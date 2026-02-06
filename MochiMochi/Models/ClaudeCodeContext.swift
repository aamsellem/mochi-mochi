import Foundation

struct ClaudeCodeContext {
    let personality: Personality
    let tasks: [MochiTask]
    let gamification: GamificationState
    let mochiName: String

    func buildPrompt(userMessage: String) -> String {
        var parts: [String] = []

        // Personality instructions
        parts.append("# Personnalite")
        parts.append("Tu t'appelles \(mochiName). \(personality.systemPrompt)")

        // Current tasks context
        let pendingTasks = tasks.filter { !$0.isCompleted }
        if !pendingTasks.isEmpty {
            parts.append("\n# Taches en cours")
            for task in pendingTasks {
                var line = "- \(task.title) [\(task.priority.displayName)]"
                if let deadline = task.deadline {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.locale = Locale(identifier: "fr_FR")
                    line += " (deadline: \(formatter.string(from: deadline)))"
                }
                if task.isOverdue {
                    line += " [EN RETARD]"
                }
                parts.append(line)
            }
        }

        // Gamification context
        parts.append("\n# Etat du Mochi")
        parts.append("- Niveau: \(gamification.level)")
        parts.append("- XP: \(gamification.currentXP)/\(gamification.xpRequiredForCurrentLevel)")
        parts.append("- Grains de riz: \(gamification.riceGrains)")
        parts.append("- Streak: \(gamification.streakDays) jours")

        // User message
        parts.append("\n# Message de l'utilisateur")
        parts.append(userMessage)

        return parts.joined(separator: "\n")
    }
}
