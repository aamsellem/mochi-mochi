import Foundation

// MARK: - App Config

struct AppConfig {
    var mochiName: String
    var personality: Personality
    var mochiColor: MochiColor
    var isOnboardingComplete: Bool
    var userName: String
    var userOccupation: String
    var userGoal: String
    var notificationFrequency: String
    var morningBriefingEnabled: Bool
    var morningBriefingHour: Int
    var weekendsProtected: Bool
    var globalShortcut: String
    var daysOff: [Int] // weekday numbers (1=Sunday, 7=Saturday)
    var meetingWatchEnabled: Bool
    var meetingCheckInterval: Int // minutes
    var meetingLookbackDays: Int // how far back to search

    init(
        mochiName: String = "Mochi",
        personality: Personality = .kawaii,
        mochiColor: MochiColor = .white,
        isOnboardingComplete: Bool = false,
        userName: String = "",
        userOccupation: String = "",
        userGoal: String = "",
        notificationFrequency: String = "normal",
        morningBriefingEnabled: Bool = true,
        morningBriefingHour: Int = 9,
        weekendsProtected: Bool = false,
        globalShortcut: String = "⌘⇧M",
        daysOff: [Int] = [],
        meetingWatchEnabled: Bool = false,
        meetingCheckInterval: Int = 30,
        meetingLookbackDays: Int = 7
    ) {
        self.mochiName = mochiName
        self.personality = personality
        self.mochiColor = mochiColor
        self.isOnboardingComplete = isOnboardingComplete
        self.userName = userName
        self.userOccupation = userOccupation
        self.userGoal = userGoal
        self.notificationFrequency = notificationFrequency
        self.morningBriefingEnabled = morningBriefingEnabled
        self.morningBriefingHour = morningBriefingHour
        self.weekendsProtected = weekendsProtected
        self.globalShortcut = globalShortcut
        self.daysOff = daysOff
        self.meetingWatchEnabled = meetingWatchEnabled
        self.meetingCheckInterval = meetingCheckInterval
        self.meetingLookbackDays = meetingLookbackDays
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
            baseDirectory.appendingPathComponent("attachments"),
            baseDirectory.appendingPathComponent("integrations/notion"),
            baseDirectory.appendingPathComponent(".claude"),
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
            ("state/meetings.md", "# Reunions\n"),
            (".claude/settings.local.json", defaultClaudeSettingsJSON()),
        ]

        for (path, content) in defaultFiles {
            let fileURL = baseDirectory.appendingPathComponent(path)
            if !fileManager.fileExists(atPath: fileURL.path) {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    private func defaultClaudeSettingsJSON() -> String {
        """
        {
          "permissions": {
            "allow": [
              "mcp__claude_ai_Notion__notion-search",
              "mcp__claude_ai_Notion__notion-fetch",
              "mcp__claude_ai_Notion__notion-create-pages",
              "mcp__claude_ai_Notion__notion-create-database",
              "mcp__claude_ai_Notion__notion-create-comment",
              "mcp__claude_ai_Notion__notion-get-comments",
              "mcp__claude_ai_Notion__notion-get-teams",
              "mcp__claude_ai_Notion__notion-get-users",
              "mcp__claude_ai_Notion__notion-update-page",
              "mcp__claude_ai_Notion__notion-update-data-source",
              "mcp__claude_ai_Notion__notion-move-pages",
              "mcp__claude_ai_Notion__notion-duplicate-page"
            ]
          }
        }
        """
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
            case "utilisateur":
                config.userName = value
            case "occupation":
                config.userOccupation = value
            case "objectif":
                config.userGoal = value
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
            case "veille_reunions":
                config.meetingWatchEnabled = value == "true"
            case "intervalle_reunions":
                if let v = Int(value) { config.meetingCheckInterval = v }
            case "historique_reunions":
                if let v = Int(value) { config.meetingLookbackDays = v }
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
        if !config.userName.isEmpty {
            lines.append("- utilisateur: \(config.userName)")
        }
        if !config.userOccupation.isEmpty {
            lines.append("- occupation: \(config.userOccupation)")
        }
        if !config.userGoal.isEmpty {
            lines.append("- objectif: \(config.userGoal)")
        }
        lines.append("- notifications: \(config.notificationFrequency)")
        lines.append("- briefing_actif: \(config.morningBriefingEnabled)")
        lines.append("- briefing_heure: \(config.morningBriefingHour)")
        lines.append("- weekends_proteges: \(config.weekendsProtected)")
        lines.append("- raccourci: \(config.globalShortcut)")
        if !config.daysOff.isEmpty {
            lines.append("- jours_off: \(config.daysOff.map(String.init).joined(separator: ", "))")
        }
        lines.append("- veille_reunions: \(config.meetingWatchEnabled)")
        lines.append("- intervalle_reunions: \(config.meetingCheckInterval)")
        lines.append("- historique_reunions: \(config.meetingLookbackDays)")
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
            var isTracked = false
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
                case "suivi":
                    isTracked = value == "true"
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
                isTracked: isTracked,
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
            lines.append("- suivi: \(task.isTracked)")
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

    // MARK: - Meeting Proposals Parsing

    func parseMeetingProposalsFromMarkdown(_ markdown: String) -> [MeetingProposal] {
        var proposals: [MeetingProposal] = []

        let proposalBlocks = markdown.components(separatedBy: "\n## ").dropFirst()
        for block in proposalBlocks {
            let lines = block.components(separatedBy: "\n")
            guard let titleLine = lines.first else { continue }

            var id = UUID()
            let meetingTitle = titleLine.trimmingCharacters(in: .whitespaces)
            var meetingNotionId = ""
            var meetingDate: Date?
            var status: ProposalStatus = .pending
            var checkedAt = Date()
            var suggestedTasks: [SuggestedTask] = []

            // Parse proposal-level properties
            var i = 1
            while i < lines.count {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

                if trimmed.hasPrefix("### ") {
                    // Start of suggested task sub-section
                    let taskTitle = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                    var taskId = UUID()
                    var taskDescription: String?
                    var taskPriority: TaskPriority = .normal
                    var taskAccepted: Bool?

                    i += 1
                    while i < lines.count {
                        let tl = lines[i].trimmingCharacters(in: .whitespaces)
                        if tl.hasPrefix("### ") || tl.hasPrefix("## ") { break }
                        guard tl.hasPrefix("- ") else { i += 1; continue }
                        let entry = String(tl.dropFirst(2))
                        let parts = entry.split(separator: ":", maxSplits: 1)
                        guard parts.count == 2 else { i += 1; continue }
                        let key = parts[0].trimmingCharacters(in: .whitespaces)
                        let value = parts[1].trimmingCharacters(in: .whitespaces)

                        switch key {
                        case "id":
                            if let parsed = UUID(uuidString: value) { taskId = parsed }
                        case "description":
                            taskDescription = value
                        case "priorite":
                            if let p = TaskPriority(rawValue: value) { taskPriority = p }
                        case "accepte":
                            if value == "true" { taskAccepted = true }
                            else if value == "false" { taskAccepted = false }
                        default:
                            break
                        }
                        i += 1
                    }

                    suggestedTasks.append(SuggestedTask(
                        id: taskId,
                        title: taskTitle,
                        description: taskDescription,
                        priority: taskPriority,
                        isAccepted: taskAccepted
                    ))
                } else if trimmed.hasPrefix("- ") {
                    let entry = String(trimmed.dropFirst(2))
                    let parts = entry.split(separator: ":", maxSplits: 1)
                    if parts.count == 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespaces)
                        let value = parts[1].trimmingCharacters(in: .whitespaces)

                        switch key {
                        case "id":
                            if let parsed = UUID(uuidString: value) { id = parsed }
                        case "notion_id":
                            meetingNotionId = value
                        case "date":
                            meetingDate = isoFormatter.date(from: value) ?? dateFormatter.date(from: value)
                        case "statut":
                            if let s = ProposalStatus(rawValue: value) { status = s }
                        case "verifie_le":
                            if let d = isoFormatter.date(from: value) { checkedAt = d }
                        default:
                            break
                        }
                    }
                    i += 1
                } else {
                    i += 1
                }
            }

            proposals.append(MeetingProposal(
                id: id,
                meetingNotionId: meetingNotionId,
                meetingTitle: meetingTitle,
                meetingDate: meetingDate,
                suggestedTasks: suggestedTasks,
                status: status,
                checkedAt: checkedAt
            ))
        }

        return proposals
    }

    func meetingProposalsToMarkdown(_ proposals: [MeetingProposal]) -> String {
        var lines = ["# Reunions", ""]

        for proposal in proposals {
            lines.append("## \(proposal.meetingTitle)")
            lines.append("- id: \(proposal.id.uuidString)")
            lines.append("- notion_id: \(proposal.meetingNotionId)")
            if let date = proposal.meetingDate {
                lines.append("- date: \(dateFormatter.string(from: date))")
            }
            lines.append("- statut: \(proposal.status.rawValue)")
            lines.append("- verifie_le: \(isoFormatter.string(from: proposal.checkedAt))")

            for task in proposal.suggestedTasks {
                lines.append("")
                lines.append("### \(task.title)")
                lines.append("- id: \(task.id.uuidString)")
                if let desc = task.description {
                    lines.append("- description: \(desc)")
                }
                lines.append("- priorite: \(task.priority.rawValue)")
                if let accepted = task.isAccepted {
                    lines.append("- accepte: \(accepted)")
                }
            }
            lines.append("")
        }

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
