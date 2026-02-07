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
    case listening
    case writing
}

// MARK: - Mochi Color

enum MochiColor: String, Codable, CaseIterable {
    case white
    case pink
    case teal
    case matcha
    case skyBlue
    case golden
    case grey
    case black
    case nightBlue
    case violet
    case pride

    var displayName: String {
        switch self {
        case .white: return "Blanc"
        case .pink: return "Rose"
        case .teal: return "Teal"
        case .matcha: return "Matcha"
        case .skyBlue: return "Bleu ciel"
        case .golden: return "Dore"
        case .grey: return "Gris"
        case .black: return "Noir"
        case .nightBlue: return "Bleu nuit"
        case .violet: return "Violet"
        case .pride: return "Pride"
        }
    }

    /// Niveau requis pour debloquer cette couleur
    var requiredLevel: Int {
        switch self {
        case .pink: return 1
        case .teal: return 1
        case .grey: return 2
        case .white: return 3
        case .matcha: return 5
        case .black: return 6
        case .skyBlue: return 8
        case .nightBlue: return 10
        case .golden: return 12
        case .violet: return 14
        case .pride: return 18
        }
    }

    /// Couleurs sombres qui necessitent un visage clair
    var isDark: Bool {
        switch self {
        case .black, .nightBlue: return true
        default: return false
        }
    }

    /// Verifie si la couleur est debloquee pour un niveau donne
    func isUnlocked(at level: Int) -> Bool {
        level >= requiredLevel
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
