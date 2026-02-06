import Foundation

// MARK: - Task Priority

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high

    var displayName: String {
        switch self {
        case .low: return "Basse"
        case .normal: return "Normale"
        case .high: return "Haute"
        }
    }

    var xpReward: Int {
        switch self {
        case .low: return 10
        case .normal: return 25
        case .high: return 50
        }
    }

    var riceReward: Int {
        switch self {
        case .low: return 2
        case .normal: return 5
        case .high: return 10
        }
    }
}

// MARK: - Mochi Task

struct MochiTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var priority: TaskPriority
    var deadline: Date?
    var isInProgress: Bool
    var isCompleted: Bool
    var completedAt: Date?
    let createdAt: Date
    var notionId: String?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        priority: TaskPriority = .normal,
        deadline: Date? = nil,
        isInProgress: Bool = false,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        notionId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.deadline = deadline
        self.isInProgress = isInProgress
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.notionId = notionId
    }

    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    var wasCompletedBeforeDeadline: Bool {
        guard let deadline = deadline, let completedAt = completedAt else { return false }
        return completedAt <= deadline
    }
}
