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

// MARK: - Meeting Source

enum MeetingSource: String, Codable {
    case outlook  // Prochaine reunion trouvee via Outlook
    case notion   // Note/CR de reunion trouvee dans Notion
}

// MARK: - Meeting Prep Status

enum MeetingPrepStatus: String, Codable {
    case discovered   // Decouverte, pas encore preparee/traitee
    case preparing    // En cours de preparation par le skill
    case prepared     // Preparee (skill) ou analysee (Notion) avec taches
    case reviewed     // Taches reviewees par l'utilisateur
    case ignored      // Ignoree par l'utilisateur ou par pattern d'exclusion
}

// MARK: - Meeting Proposal

struct MeetingProposal: Identifiable, Codable {
    let id: UUID
    var source: MeetingSource      // Outlook ou Notion
    var sourceId: String           // Outlook event ID ou Notion page ID
    var meetingTitle: String
    var meetingDate: Date?
    var meetingEndDate: Date?
    var attendees: [String]
    var location: String?
    var suggestedTasks: [SuggestedTask]
    var status: MeetingPrepStatus
    var preReadNotionUrl: String?
    var agendaNotionUrl: String?
    var prepSummary: String?
    let checkedAt: Date

    init(
        id: UUID = UUID(),
        source: MeetingSource = .notion,
        sourceId: String,
        meetingTitle: String,
        meetingDate: Date? = nil,
        meetingEndDate: Date? = nil,
        attendees: [String] = [],
        location: String? = nil,
        suggestedTasks: [SuggestedTask] = [],
        status: MeetingPrepStatus = .discovered,
        preReadNotionUrl: String? = nil,
        agendaNotionUrl: String? = nil,
        prepSummary: String? = nil,
        checkedAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.sourceId = sourceId
        self.meetingTitle = meetingTitle
        self.meetingDate = meetingDate
        self.meetingEndDate = meetingEndDate
        self.attendees = attendees
        self.location = location
        self.suggestedTasks = suggestedTasks
        self.status = status
        self.preReadNotionUrl = preReadNotionUrl
        self.agendaNotionUrl = agendaNotionUrl
        self.prepSummary = prepSummary
        self.checkedAt = checkedAt
    }
}
