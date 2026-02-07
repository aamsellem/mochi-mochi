import Foundation

// MARK: - Errors

enum ClaudeCodeError: LocalizedError {
    case notInstalled
    case timeout
    case processError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Claude Code n'est pas installe ou introuvable."
        case .timeout:
            return "Claude Code n'a pas repondu dans le delai imparti."
        case .processError(let message):
            return "Erreur Claude Code: \(message)"
        case .invalidResponse:
            return "Reponse invalide de Claude Code."
        }
    }
}

// MARK: - Claude Code JSON Response

private struct ClaudeCodeResponse: Decodable {
    let result: String
    let session_id: String?
    let is_error: Bool?
}

// MARK: - Claude Code Service

final class ClaudeCodeService: @unchecked Sendable {
    private let timeoutSeconds: TimeInterval = 120
    private var currentSessionId: String?

    // MARK: - Public API

    func isClaudeCodeInstalled() -> Bool {
        claudeCodePath() != nil
    }

    /// Send a message within the current session. Creates a new session on first call.
    /// Claude Code reads CLAUDE.md automatically from the working directory.
    func send(message: String, workingDirectory: URL) async throws -> String {
        guard isClaudeCodeInstalled() else {
            throw ClaudeCodeError.notInstalled
        }

        let isNewSession = currentSessionId == nil
        var args = ["-p", message, "--output-format", "json"]

        if let sessionId = currentSessionId {
            args += ["--resume", sessionId]
        }

        let rawOutput = try await executeClaudeCode(arguments: args, workingDirectory: workingDirectory)
        return try parseResponse(rawOutput, isNewSession: isNewSession)
    }

    /// Start a fresh session (e.g. on /end command)
    func resetSession() {
        currentSessionId = nil
    }

    /// Quick one-shot generation (no session, no interference with chat)
    func generateQuick(prompt: String, workingDirectory: URL? = nil) async throws -> String {
        guard isClaudeCodeInstalled() else {
            throw ClaudeCodeError.notInstalled
        }
        let args = ["-p", prompt, "--output-format", "json"]
        let dir = workingDirectory ?? URL(fileURLWithPath: NSHomeDirectory())
        let rawOutput = try await executeClaudeCode(arguments: args, workingDirectory: dir)
        guard let data = rawOutput.data(using: .utf8) else {
            throw ClaudeCodeError.invalidResponse
        }
        let response = try JSONDecoder().decode(ClaudeCodeResponse.self, from: data)
        if response.is_error == true {
            throw ClaudeCodeError.processError(response.result)
        }
        return response.result
    }

    // MARK: - Private

    private func claudeCodePath() -> String? {
        let paths = [
            "\(NSHomeDirectory())/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func parseResponse(_ rawOutput: String, isNewSession: Bool) throws -> String {
        guard let data = rawOutput.data(using: .utf8) else {
            throw ClaudeCodeError.invalidResponse
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaudeCodeResponse.self, from: data)

        if response.is_error == true {
            throw ClaudeCodeError.processError(response.result)
        }

        // Capture session ID from first response
        if isNewSession, let sessionId = response.session_id {
            currentSessionId = sessionId
        }

        return response.result
    }

    private func buildProcessEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let homeDir = NSHomeDirectory()
        let extraPaths = [
            "\(homeDir)/.local/bin",
            "\(homeDir)/.nvm/current/bin",
            "/usr/local/bin",
            "/opt/homebrew/bin"
        ]
        let currentPath = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = (extraPaths + [currentPath]).joined(separator: ":")
        env["HOME"] = homeDir
        return env
    }

    private func executeClaudeCode(arguments: [String], workingDirectory: URL) async throws -> String {
        guard let executablePath = claudeCodePath() else {
            throw ClaudeCodeError.notInstalled
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.environment = buildProcessEnvironment()
        process.currentDirectoryURL = workingDirectory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let resumeLock = NSLock()

            @Sendable func safeResume(with result: Result<String, Error>) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(with: result)
            }

            // Timeout
            let timeoutWork = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                }
                safeResume(with: .failure(ClaudeCodeError.timeout))
            }
            DispatchQueue.global().asyncAfter(
                deadline: .now() + timeoutSeconds,
                execute: timeoutWork
            )

            process.terminationHandler = { _ in
                timeoutWork.cancel()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus == 0 && !output.isEmpty {
                    safeResume(with: .success(output))
                } else {
                    let message = errorOutput.isEmpty ? (output.isEmpty ? "No output" : output) : errorOutput
                    safeResume(with: .failure(ClaudeCodeError.processError(message)))
                }
            }

            do {
                try process.run()
            } catch {
                timeoutWork.cancel()
                safeResume(with: .failure(ClaudeCodeError.processError(error.localizedDescription)))
            }
        }
    }
}
