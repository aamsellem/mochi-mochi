import Foundation

// MARK: - App Config

struct AppConfig {
    var mochiName: String
    var personality: Personality
    var mochiColor: MochiColor
    var isOnboardingComplete: Bool
    var notificationFrequency: String
    var morningBriefingEnabled: Bool
    var morningBriefingHour: Int
    var weekendsProtected: Bool
    var globalShortcut: String
    var daysOff: [Int] // weekday numbers (1=Sunday, 7=Saturday)

    init(
        mochiName: String = "Mochi",
        personality: Personality = .kawaii,
        mochiColor: MochiColor = .white,
        isOnboardingComplete: Bool = false,
        notificationFrequency: String = "normal",
        morningBriefingEnabled: Bool = true,
        morningBriefingHour: Int = 9,
        weekendsProtected: Bool = false,
        globalShortcut: String = "⌘⇧M",
        daysOff: [Int] = []
    ) {
        self.mochiName = mochiName
        self.personality = personality
        self.mochiColor = mochiColor
        self.isOnboardingComplete = isOnboardingComplete
        self.notificationFrequency = notificationFrequency
        self.morningBriefingEnabled = morningBriefingEnabled
        self.morningBriefingHour = morningBriefingHour
        self.weekendsProtected = weekendsProtected
        self.globalShortcut = globalShortcut
        self.daysOff = daysOff
    }
}

// MARK: - Markdown Storage Error

enum MarkdownStorageError: Error {
    case fileNotFound(String)
    case writeError(String)
    case parseError(String)
}

// MARK: - Markdown Storage

final class MarkdownStorage {
    static let shared = MarkdownStorage()

    let baseDirectory: URL

    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let storagePathKey = "mochiStoragePath"

    static var storedBaseDirectory: URL {
        if let saved = UserDefaults.standard.string(forKey: storagePathKey) {
            return URL(fileURLWithPath: saved)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".mochi-mochi")
    }

    static func setStoragePath(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: storagePathKey)
    }

    init(baseDirectory: URL? = nil) {
        if let baseDirectory = baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = MarkdownStorage.storedBaseDirectory
        }
    }

    // MARK: - Directory Structure

    func ensureDirectoryStructure() throws {
        let directories = [
            baseDirectory,
            baseDirectory.appendingPathComponent("state"),
            baseDirectory.appendingPathComponent("sessions"),
            baseDirectory.appendingPathComponent("content/notes"),
            baseDirectory.appendingPathComponent("content/ideas"),
            baseDirectory.appendingPathComponent("inventory"),
            baseDirectory.appendingPathComponent("integrations/notion"),
        ]

        for dir in directories {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Create default files if they don't exist
        let defaultFiles: [(String, String)] = [
            ("config.md", defaultConfigMarkdown()),
            ("state/current.md", "# Taches en cours\n"),
            ("state/goals.md", "# Objectifs\n"),
            ("state/mochi.md", defaultMochiStateMarkdown()),
            ("inventory/items.md", "# Inventaire\n"),
            ("integrations/notion/config.md", "# Notion\n\n- active: false\n"),
        ]

        for (path, content) in defaultFiles {
            let fileURL = baseDirectory.appendingPathComponent(path)
            if !fileManager.fileExists(atPath: fileURL.path) {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    // MARK: - File Operations

    func read(file: String) -> String? {
        let fileURL = baseDirectory.appendingPathComponent(file)
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    func write(file: String, content: String) throws {
        let fileURL = baseDirectory.appendingPathComponent(file)
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func append(file: String, content: String) throws {
        let fileURL = baseDirectory.appendingPathComponent(file)
        if fileManager.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            handle.seekToEndOfFile()
            if let data = content.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try write(file: file, content: content)
        }
    }

    func listFiles(in directory: String) -> [String] {
        let dirURL = baseDirectory.appendingPathComponent(directory)
        guard let contents = try? fileManager.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return contents.map { $0.lastPathComponent }.sorted()
    }

    // MARK: - Session File

    func sessionFile(for date: Date = Date()) -> String {
        "sessions/\(dateFormatter.string(from: date)).md"
    }

    // MARK: - Config Parsing

    func parseConfigFromMarkdown(_ markdown: String) -> AppConfig {
        var config = AppConfig()

        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") else { continue }
            let entry = String(trimmed.dropFirst(2))
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch key {
            case "nom":
                config.mochiName = value
            case "personnalite":
                if let p = Personality(rawValue: value) {
                    config.personality = p
                }
            case "couleur":
                if let c = MochiColor(rawValue: value) {
                    config.mochiColor = c
                }
            case "onboarding":
                config.isOnboardingComplete = value == "true"
            case "notifications":
                config.notificationFrequency = value
            case "briefing_actif":
                config.morningBriefingEnabled = value == "true"
            case "briefing_heure":
                if let h = Int(value) { config.morningBriefingHour = h }
            case "weekends_proteges":
                config.weekendsProtected = value == "true"
            case "raccourci":
                config.globalShortcut = value
            case "jours_off":
                config.daysOff = value.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            default:
                break
            }
        }

        return config
    }

    func configToMarkdown(_ config: AppConfig) -> String {
        var lines = ["# Configuration Mochi Mochi", ""]
        lines.append("- nom: \(config.mochiName)")
        lines.append("- personnalite: \(config.personality.rawValue)")
        lines.append("- couleur: \(config.mochiColor.rawValue)")
        lines.append("- onboarding: \(config.isOnboardingComplete)")
        lines.append("- notifications: \(config.notificationFrequency)")
        lines.append("- briefing_actif: \(config.morningBriefingEnabled)")
        lines.append("- briefing_heure: \(config.morningBriefingHour)")
        lines.append("- weekends_proteges: \(config.weekendsProtected)")
        lines.append("- raccourci: \(config.globalShortcut)")
        if !config.daysOff.isEmpty {
            lines.append("- jours_off: \(config.daysOff.map(String.init).joined(separator: ", "))")
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    // MARK: - Tasks Parsing

    func parseTasksFromMarkdown(_ markdown: String) -> [MochiTask] {
        var tasks: [MochiTask] = []

        let taskBlocks = markdown.components(separatedBy: "\n## ").dropFirst()
        for block in taskBlocks {
            let lines = block.components(separatedBy: "\n")
            guard let titleLine = lines.first else { continue }

            var id = UUID()
            var title = titleLine.trimmingCharacters(in: .whitespaces)
            var description: String?
            var priority: TaskPriority = .normal
            var deadline: Date?
            var isInProgress = false
            var isCompleted = false
            var completedAt: Date?
            var createdAt = Date()
            var notionId: String?

            for line in lines.dropFirst() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("- ") else { continue }
                let entry = String(trimmed.dropFirst(2))
                let parts = entry.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)

                switch key {
                case "id":
                    if let parsed = UUID(uuidString: value) { id = parsed }
                case "description":
                    description = value
                case "priorite":
                    if let p = TaskPriority(rawValue: value) { priority = p }
                case "deadline":
                    deadline = isoFormatter.date(from: value)
                case "en_cours":
                    isInProgress = value == "true"
                case "complete":
                    isCompleted = value == "true"
                case "complete_le":
                    completedAt = isoFormatter.date(from: value)
                case "cree_le":
                    if let d = isoFormatter.date(from: value) { createdAt = d }
                case "notion_id":
                    notionId = value
                default:
                    break
                }
            }

            // Remove checkbox prefix if present
            if title.hasPrefix("[x] ") || title.hasPrefix("[X] ") {
                isCompleted = true
                title = String(title.dropFirst(4))
            } else if title.hasPrefix("[ ] ") {
                title = String(title.dropFirst(4))
            }

            tasks.append(MochiTask(
                id: id,
                title: title,
                description: description,
                priority: priority,
                deadline: deadline,
                isInProgress: isInProgress,
                isCompleted: isCompleted,
                completedAt: completedAt,
                createdAt: createdAt,
                notionId: notionId
            ))
        }

        return tasks
    }

    func tasksToMarkdown(_ tasks: [MochiTask]) -> String {
        var lines = ["# Taches en cours", ""]

        for task in tasks {
            let checkbox = task.isCompleted ? "[x]" : "[ ]"
            lines.append("## \(checkbox) \(task.title)")
            lines.append("- id: \(task.id.uuidString)")
            lines.append("- priorite: \(task.priority.rawValue)")
            if let desc = task.description {
                lines.append("- description: \(desc)")
            }
            if let deadline = task.deadline {
                lines.append("- deadline: \(isoFormatter.string(from: deadline))")
            }
            lines.append("- en_cours: \(task.isInProgress)")
            lines.append("- complete: \(task.isCompleted)")
            if let completedAt = task.completedAt {
                lines.append("- complete_le: \(isoFormatter.string(from: completedAt))")
            }
            lines.append("- cree_le: \(isoFormatter.string(from: task.createdAt))")
            if let notionId = task.notionId {
                lines.append("- notion_id: \(notionId)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Gamification Parsing

    func parseGamificationFromMarkdown(_ markdown: String) -> GamificationState {
        var state = GamificationState()

        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") else { continue }
            let entry = String(trimmed.dropFirst(2))
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch key {
            case "niveau":
                if let v = Int(value) { state.level = v }
            case "xp_actuel":
                if let v = Int(value) { state.currentXP = v }
            case "xp_total":
                if let v = Int(value) { state.totalXP = v }
            case "grains_de_riz":
                if let v = Int(value) { state.riceGrains = v }
            case "streak":
                if let v = Int(value) { state.streakDays = v }
            case "derniere_activite":
                state.lastActiveDate = isoFormatter.date(from: value)
            default:
                break
            }
        }

        return state
    }

    func gamificationToMarkdown(_ state: GamificationState) -> String {
        var lines = ["# Etat du Mochi", ""]
        lines.append("- niveau: \(state.level)")
        lines.append("- xp_actuel: \(state.currentXP)")
        lines.append("- xp_total: \(state.totalXP)")
        lines.append("- grains_de_riz: \(state.riceGrains)")
        lines.append("- streak: \(state.streakDays)")
        if let lastActive = state.lastActiveDate {
            lines.append("- derniere_activite: \(isoFormatter.string(from: lastActive))")
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    // MARK: - Default Content

    private func defaultConfigMarkdown() -> String {
        configToMarkdown(AppConfig())
    }

    private func defaultMochiStateMarkdown() -> String {
        gamificationToMarkdown(GamificationState())
    }
}
