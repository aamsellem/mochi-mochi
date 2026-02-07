import Foundation

// MARK: - Suggested Task

struct SuggestedTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var priority: TaskPriority
    var isAccepted: Bool?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        priority: TaskPriority = .normal,
        isAccepted: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.isAccepted = isAccepted
    }
}

// MARK: - Proposal Status

enum ProposalStatus: String, Codable {
    case pending
    case reviewed
}

// MARK: - Meeting Proposal

struct MeetingProposal: Identifiable, Codable {
    let id: UUID
    let meetingNotionId: String
    var meetingTitle: String
    var meetingDate: Date?
    var suggestedTasks: [SuggestedTask]
    var status: ProposalStatus
    let checkedAt: Date

    init(
        id: UUID = UUID(),
        meetingNotionId: String,
        meetingTitle: String,
        meetingDate: Date? = nil,
        suggestedTasks: [SuggestedTask] = [],
        status: ProposalStatus = .pending,
        checkedAt: Date = Date()
    ) {
        self.id = id
        self.meetingNotionId = meetingNotionId
        self.meetingTitle = meetingTitle
        self.meetingDate = meetingDate
        self.suggestedTasks = suggestedTasks
        self.status = status
        self.checkedAt = checkedAt
    }
}
