import Foundation

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case assistant
}

// MARK: - Message

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
