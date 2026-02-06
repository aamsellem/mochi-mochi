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
    case teal
    case matcha
    case skyBlue
    case golden

    var displayName: String {
        switch self {
        case .white: return "Blanc"
        case .pink: return "Rose"
        case .teal: return "Teal"
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
        color: MochiColor = .pink
    ) {
        self.name = name
        self.emotion = emotion
        self.equippedItems = equippedItems
        self.color = color
    }

    /// Baseline emotion based on tasks/gamification state (used as fallback)
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

    /// React to a received assistant message by analyzing content
    mutating func reactToResponse(_ content: String) {
        let lower = content.lowercased()

        if lower.contains("bravo") || lower.contains("felicitation") || lower.contains("bien joue")
            || lower.contains("genial") || lower.contains("excellent") || lower.contains("super")
            || lower.contains("fier") || lower.contains("champion") {
            emotion = .excited
        } else if lower.contains("retard") || lower.contains("deadline") || lower.contains("urgent")
            || lower.contains("attention") || lower.contains("oublie") {
            emotion = .worried
        } else if lower.contains("pause") || lower.contains("repos") || lower.contains("dors")
            || lower.contains("sieste") || lower.contains("zzz") {
            emotion = .sleeping
        } else if lower.contains("focus") || lower.contains("concentr") || lower.contains("travail") {
            emotion = .focused
        } else if lower.contains("triste") || lower.contains("perdu") || lower.contains("dommage")
            || lower.contains("desole") {
            emotion = .sad
        } else if lower.contains("!") || lower.contains("haha") || lower.contains("lol")
            || lower.contains("😄") || lower.contains("😊") || lower.contains("✨") {
            emotion = .happy
        } else {
            emotion = .happy // Default after a response: content and engaged
        }
    }
}
