import Foundation

struct ClaudeCodeContext {
    let personality: Personality
    let tasks: [MochiTask]
    let gamification: GamificationState
    let mochiName: String
    let userName: String
    let userOccupation: String
    let userGoal: String

    /// Build the CLAUDE.md content that Claude Code reads automatically from the working directory
    func buildClaudeMd() -> String {
        var parts: [String] = []

        parts.append("# Mochi Mochi — Contexte Compagnon")
        parts.append("")
        parts.append("Tu es un compagnon virtuel gamifie dans une application macOS.")
        parts.append("Ce fichier contient ton contexte. Il est mis a jour automatiquement par l'application.")

        // User context
        if !userName.isEmpty {
            parts.append("")
            parts.append("## Utilisateur")
            parts.append("- Prenom : \(userName)")
            if !userOccupation.isEmpty {
                parts.append("- Activite : \(userOccupation)")
            }
            if !userGoal.isEmpty {
                parts.append("- Objectif principal : \(userGoal)")
            }
            parts.append("")
            parts.append("Utilise son prenom pour t'adresser a lui.")
        }

        // Personality instructions
        parts.append("")
        parts.append("## Personnalite")
        parts.append("Tu t'appelles **\(mochiName)**. \(personality.systemPrompt)")
        parts.append("Reponds toujours en francais et dans le ton de ta personnalite.")

        // Action markers
        parts.append("")
        parts.append("## Actions structurees")
        parts.append("""
        Quand l'utilisateur te demande d'ajouter, creer ou noter une tache, tu DOIS inclure un marqueur dans ta reponse pour chaque tache :
        - Format : `[TASK:titre de la tache]`
        - Pour une tache haute priorite : `[TASK_HIGH:titre]`
        - Pour une tache basse priorite : `[TASK_LOW:titre]`
        - Tu peux en mettre plusieurs dans une meme reponse.
        - Le marqueur doit etre sur sa propre ligne.
        - Continue a repondre normalement avec ta personnalite en plus des marqueurs.
        - N'utilise PAS ces marqueurs si l'utilisateur ne demande pas explicitement d'ajouter une tache.

        Exemple de reponse quand on te demande d'ajouter "faire les courses" :
        > C'est note ! Je t'ajoute ca~
        > [TASK:Faire les courses]
        """)

        // Current tasks context
        let pendingTasks = tasks.filter { !$0.isCompleted }
        if !pendingTasks.isEmpty {
            parts.append("")
            parts.append("## Taches en cours")
            for task in pendingTasks {
                var line = "- \(task.title) [\(task.priority.displayName)]"
                if let deadline = task.deadline {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.locale = Locale(identifier: "fr_FR")
                    line += " (deadline: \(formatter.string(from: deadline)))"
                }
                if task.isOverdue {
                    line += " **[EN RETARD]**"
                }
                parts.append(line)
            }
        }

        let completedToday = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }
        if !completedToday.isEmpty {
            parts.append("")
            parts.append("## Taches completees aujourd'hui")
            for task in completedToday {
                parts.append("- ~~\(task.title)~~")
            }
        }

        // Gamification context
        parts.append("")
        parts.append("## Etat du Mochi")
        parts.append("- Niveau : \(gamification.level)")
        parts.append("- XP : \(gamification.currentXP)/\(gamification.xpRequiredForCurrentLevel)")
        parts.append("- Grains de riz : \(gamification.riceGrains)")
        parts.append("- Streak : \(gamification.streakDays) jour(s)")
        parts.append("")

        return parts.joined(separator: "\n")
    }
}
