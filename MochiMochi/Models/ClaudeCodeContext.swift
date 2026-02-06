import Foundation

struct ClaudeCodeContext {
    let personality: Personality
    let tasks: [MochiTask]
    let gamification: GamificationState
    let mochiName: String

    /// System prompt injected once at session start (via --append-system-prompt)
    func buildSystemPrompt() -> String {
        var parts: [String] = []

        // Personality instructions
        parts.append("# Personnalite")
        parts.append("Tu t'appelles \(mochiName). \(personality.systemPrompt)")
        parts.append("Reponds toujours en francais et dans le ton de ta personnalite.")

        // Action markers
        parts.append("""

        # Actions structurees
        Quand l'utilisateur te demande d'ajouter, creer ou noter une tache, tu DOIS inclure un marqueur dans ta reponse pour chaque tache :
        - Format : [TASK:titre de la tache]
        - Pour une tache haute priorite : [TASK_HIGH:titre]
        - Pour une tache basse priorite : [TASK_LOW:titre]
        - Tu peux en mettre plusieurs dans une meme reponse.
        - Le marqueur doit etre sur sa propre ligne.
        - Continue a repondre normalement avec ta personnalite en plus des marqueurs.
        - N'utilise PAS ces marqueurs si l'utilisateur ne demande pas explicitement d'ajouter une tache.
        Exemple de reponse quand on te demande d'ajouter "faire les courses" :
        "C'est note ! Je t'ajoute ca~
        [TASK:Faire les courses]"
        """)

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

        return parts.joined(separator: "\n")
    }
}
