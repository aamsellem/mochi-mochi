import Foundation

// MARK: - Mochi Emotion

enum MochiEmotion: String, Codable, CaseIterable {
    case idle
    case happy
    case excited
    case focused
    case sleeping
    case worried
    case sad
    case proud
    case thinking
}

// MARK: - Mochi Color

enum MochiColor: String, Codable, CaseIterable {
    case white
    case pink
    case matcha
    case skyBlue
    case golden

    var displayName: String {
        switch self {
        case .white: return "Blanc"
        case .pink: return "Rose"
        case .matcha: return "Matcha"
        case .skyBlue: return "Bleu ciel"
        case .golden: return "Dore"
        }
    }
}

// MARK: - Mochi Character

struct MochiCharacter: Codable {
    var name: String
    var emotion: MochiEmotion
    var equippedItems: [ShopItem]
    var color: MochiColor

    init(
        name: String = "Mochi",
        emotion: MochiEmotion = .idle,
        equippedItems: [ShopItem] = [],
        color: MochiColor = .white
    ) {
        self.name = name
        self.emotion = emotion
        self.equippedItems = equippedItems
        self.color = color
    }

    mutating func updateEmotion(from gamification: GamificationState, tasks: [MochiTask]) {
        let overdueTasks = tasks.filter { $0.isOverdue }
        let completedToday = tasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }

        if !overdueTasks.isEmpty {
            emotion = overdueTasks.count >= 3 ? .sad : .worried
        } else if completedToday.count >= 5 {
            emotion = .proud
        } else if completedToday.count >= 1 {
            emotion = .happy
        } else if gamification.streakDays >= 7 {
            emotion = .excited
        } else {
            emotion = .idle
        }
    }
}
