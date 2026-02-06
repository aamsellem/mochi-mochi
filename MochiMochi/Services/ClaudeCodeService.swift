import Foundation

// MARK: - Errors

enum ClaudeCodeError: LocalizedError {
    case notInstalled
    case timeout
    case processError(String)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Claude Code n'est pas installe ou introuvable."
        case .timeout:
            return "Claude Code n'a pas repondu dans le delai imparti (30s)."
        case .processError(let message):
            return "Erreur Claude Code: \(message)"
        }
    }
}

// MARK: - Claude Code Service

final class ClaudeCodeService: @unchecked Sendable {
    private let timeoutSeconds: TimeInterval = 30

    // MARK: - Public API

    func isClaudeCodeInstalled() -> Bool {
        let paths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude"
        ]
        return paths.contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func send(message: String, personality: Personality, context: ClaudeCodeContext) async throws -> String {
        guard isClaudeCodeInstalled() else {
            throw ClaudeCodeError.notInstalled
        }

        let enrichedPrompt = context.buildPrompt(userMessage: message)
        return try await executeClaudeCode(prompt: enrichedPrompt)
    }

    // MARK: - Private

    private func claudeCodePath() -> String? {
        let paths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude"
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func executeClaudeCode(prompt: String) async throws -> String {
        guard let executablePath = claudeCodePath() else {
            throw ClaudeCodeError.notInstalled
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["--print", "--prompt", prompt]

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

                if process.terminationStatus == 0 {
                    safeResume(with: .success(output))
                } else {
                    let message = errorOutput.isEmpty ? output : errorOutput
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
