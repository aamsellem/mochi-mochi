import Foundation

// MARK: - Errors

enum MemoryError: LocalizedError {
    case initializationFailed(String)
    case saveFailed(String)
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Echec d'initialisation de la memoire: \(message)"
        case .saveFailed(let message):
            return "Echec de sauvegarde: \(message)"
        case .loadFailed(let message):
            return "Echec de chargement: \(message)"
        }
    }
}

// MARK: - Memory Service

final class MemoryService {
    private let storage: MarkdownStorage

    init(storage: MarkdownStorage = .shared) {
        self.storage = storage
        try? storage.ensureDirectoryStructure()
    }

    // MARK: - Config

    func loadConfig() -> AppConfig? {
        guard let content = storage.read(file: "config.md") else { return nil }
        return storage.parseConfigFromMarkdown(content)
    }

    func saveConfig(_ config: AppConfig) {
        let markdown = storage.configToMarkdown(config)
        try? storage.write(file: "config.md", content: markdown)
    }

    // MARK: - Tasks

    func loadTasks() -> [MochiTask] {
        guard let content = storage.read(file: "state/current.md") else { return [] }
        return storage.parseTasksFromMarkdown(content)
    }

    func saveTasks(_ tasks: [MochiTask]) {
        let markdown = storage.tasksToMarkdown(tasks)
        try? storage.write(file: "state/current.md", content: markdown)
    }

    // MARK: - Mochi State (Gamification)

    func loadMochiState() -> GamificationState? {
        guard let content = storage.read(file: "state/mochi.md") else { return nil }
        return storage.parseGamificationFromMarkdown(content)
    }

    func saveMochiState(_ state: GamificationState) {
        let markdown = storage.gamificationToMarkdown(state)
        try? storage.write(file: "state/mochi.md", content: markdown)
    }

    // MARK: - Goals

    func loadGoals() -> [String] {
        guard let content = storage.read(file: "state/goals.md") else { return [] }
        return content
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)) }
    }

    func saveGoals(_ goals: [String]) {
        var lines = ["# Objectifs", ""]
        for goal in goals {
            lines.append("- \(goal)")
        }
        lines.append("")
        try? storage.write(file: "state/goals.md", content: lines.joined(separator: "\n"))
    }

    // MARK: - Sessions

    func saveSession(messages: [Message], date: Date = Date()) {
        let file = storage.sessionFile(for: date)
        var lines = ["# Session du \(formattedDate(date))", ""]

        for message in messages {
            let role = message.role == .user ? "Utilisateur" : "Mochi"
            let time = formattedTime(message.timestamp)
            lines.append("### \(role) (\(time))")
            lines.append(message.content)
            lines.append("")
        }

        try? storage.write(file: file, content: lines.joined(separator: "\n"))
    }

    func loadSession(for date: Date = Date()) -> String? {
        let file = storage.sessionFile(for: date)
        return storage.read(file: file)
    }

    // MARK: - Inventory

    func loadInventory() -> [ShopItem] {
        guard let content = storage.read(file: "inventory/items.md") else { return [] }
        return parseInventoryFromMarkdown(content)
    }

    func saveInventory(_ items: [ShopItem]) {
        let markdown = inventoryToMarkdown(items)
        try? storage.write(file: "inventory/items.md", content: markdown)
    }

    // MARK: - Private Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    private func parseInventoryFromMarkdown(_ markdown: String) -> [ShopItem] {
        var items: [ShopItem] = []

        let blocks = markdown.components(separatedBy: "\n## ").dropFirst()
        for block in blocks {
            let lines = block.components(separatedBy: "\n")
            guard let nameLine = lines.first else { continue }

            var id = UUID()
            let name = nameLine.trimmingCharacters(in: .whitespaces)
            var category: ItemCategory = .accessory
            var price = 0
            var requiredLevel = 1
            var isOwned = false
            var isEquipped = false

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
                case "categorie":
                    if let c = ItemCategory(rawValue: value) { category = c }
                case "prix":
                    if let v = Int(value) { price = v }
                case "niveau_requis":
                    if let v = Int(value) { requiredLevel = v }
                case "possede":
                    isOwned = value == "true"
                case "equipe":
                    isEquipped = value == "true"
                default:
                    break
                }
            }

            items.append(ShopItem(
                id: id,
                name: name,
                category: category,
                price: price,
                requiredLevel: requiredLevel,
                isOwned: isOwned,
                isEquipped: isEquipped
            ))
        }

        return items
    }

    private func inventoryToMarkdown(_ items: [ShopItem]) -> String {
        var lines = ["# Inventaire", ""]

        for item in items {
            lines.append("## \(item.name)")
            lines.append("- id: \(item.id.uuidString)")
            lines.append("- categorie: \(item.category.rawValue)")
            lines.append("- prix: \(item.price)")
            lines.append("- niveau_requis: \(item.requiredLevel)")
            lines.append("- possede: \(item.isOwned)")
            lines.append("- equipe: \(item.isEquipped)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
