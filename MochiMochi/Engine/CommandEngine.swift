import Foundation

// MARK: - Command Engine

@MainActor
enum CommandEngine {

    static func execute(_ result: SlashCommandResult, appState: AppState) async {
        switch result.command {
        case .bonjour:
            await executeBonjour(appState: appState)
        case .add:
            executeAdd(arguments: result.arguments, appState: appState)
        case .bilan:
            await executeBilan(appState: appState)
        case .focus:
            executeFocus(appState: appState)
        case .pause:
            executePause(appState: appState)
        case .objectif:
            await executeObjectif(arguments: result.arguments, appState: appState)
        case .humeur:
            executeHumeur(appState: appState)
        case .inventaire:
            executeInventaire(appState: appState)
        case .boutique:
            executeBoutique(appState: appState)
        case .stats:
            executeStats(appState: appState)
        case .notion:
            await executeNotion(appState: appState)
        case .settings:
            executeSettings(appState: appState)
        case .help:
            executeHelp(appState: appState)
        case .end:
            executeEnd(appState: appState)
        case .unknown:
            await executeUnknown(rawInput: result.arguments ?? result.rawInput, appState: appState)
        }
    }

    // MARK: - /bonjour

    private static func executeBonjour(appState: AppState) async {
        let pendingTasks = appState.tasks.filter { !$0.isCompleted }
        let overdueTasks = pendingTasks.filter { $0.isOverdue }
        let todayDeadlines = pendingTasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return Calendar.current.isDateInToday(deadline)
        }

        var briefing = "Voici ton briefing :\n"
        briefing += "- \(pendingTasks.count) tache(s) en cours\n"

        if !overdueTasks.isEmpty {
            briefing += "- \(overdueTasks.count) tache(s) en retard\n"
        }

        if !todayDeadlines.isEmpty {
            briefing += "- \(todayDeadlines.count) deadline(s) aujourd'hui\n"
        }

        briefing += "- Streak : \(appState.gamification.streakDays) jour(s)\n"
        briefing += "- Niveau \(appState.gamification.level) (\(appState.gamification.currentXP)/\(appState.gamification.xpRequiredForCurrentLevel) XP)"

        let context = ClaudeCodeContext(
            personality: appState.currentPersonality,
            tasks: appState.tasks,
            gamification: appState.gamification,
            mochiName: appState.mochi.name
        )

        do {
            let response = try await appState.claudeCodeService.send(
                message: "Donne-moi un briefing matinal en utilisant ces infos : \(briefing)",
                personality: appState.currentPersonality,
                context: context
            )
            appState.messages.append(Message(role: .assistant, content: response))
        } catch {
            appState.messages.append(Message(role: .assistant, content: briefing))
        }
    }

    // MARK: - /add

    private static func executeAdd(arguments: String?, appState: AppState) {
        guard let title = arguments, !title.isEmpty else {
            appState.messages.append(Message(
                role: .assistant,
                content: "Usage : /add [titre de la tache]\nExemple : /add Finaliser le rapport"
            ))
            return
        }

        let task = MochiTask(title: title)
        appState.addTask(task)

        let personality = appState.currentPersonality
        let confirmation: String
        switch personality {
        case .kawaii:
            confirmation = "Tache ajoutee : \"\(title)\" ! Tu vas gerer ~"
        case .sensei:
            confirmation = "Tache \"\(title)\" ajoutee. Ne la laisse pas trainer."
        case .pote:
            confirmation = "C'est note : \"\(title)\". Fais-le avant de procrastiner."
        case .butler:
            confirmation = "Bien note, Monsieur. \"\(title)\" a ete ajoute a votre liste."
        case .coach:
            confirmation = "NOUVELLE TACHE : \"\(title)\" ! On va la DETRUIRE !"
        case .sage:
            confirmation = "La tache \"\(title)\" rejoint ton chemin. Un pas apres l'autre."
        case .chat:
            confirmation = "\"\(title)\", ajoute. J'espere que tu la feras, cette fois."
        case .heroique:
            confirmation = "Une nouvelle quete s'ajoute a ton epopee : \"\(title)\" !"
        }

        appState.messages.append(Message(role: .assistant, content: confirmation))
    }

    // MARK: - /bilan

    private static func executeBilan(appState: AppState) async {
        let completedToday = appState.tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }

        var summary = "Bilan du jour :\n"
        summary += "- \(completedToday.count) tache(s) completee(s)\n"
        summary += "- Streak : \(appState.gamification.streakDays) jour(s)\n"
        summary += "- Niveau \(appState.gamification.level) | \(appState.gamification.riceGrains) grains de riz"

        let context = ClaudeCodeContext(
            personality: appState.currentPersonality,
            tasks: appState.tasks,
            gamification: appState.gamification,
            mochiName: appState.mochi.name
        )

        do {
            let response = try await appState.claudeCodeService.send(
                message: "Fais un bilan de ma journee avec ces infos : \(summary)",
                personality: appState.currentPersonality,
                context: context
            )
            appState.messages.append(Message(role: .assistant, content: response))
        } catch {
            appState.messages.append(Message(role: .assistant, content: summary))
        }
    }

    // MARK: - /focus

    private static func executeFocus(appState: AppState) {
        appState.mochi.emotion = .focused
        appState.notificationService.cancelAll()

        let message: String
        switch appState.currentPersonality {
        case .kawaii: message = "Mode focus active ! Je reste silencieux pour toi~ Concentre-toi bien !"
        case .sensei: message = "Mode focus. Silence total. Travaille."
        case .pote: message = "Ok, mode focus. Je te laisse tranquille. Fais du bon boulot."
        case .butler: message = "Mode concentration active, Monsieur. Je ne vous derangerai plus."
        case .coach: message = "MODE FOCUS ! ZERO DISTRACTION ! DONNE TOUT !"
        case .sage: message = "Le silence est l'allie de la concentration. Mode focus active."
        case .chat: message = "Enfin tu te concentres. Je vais faire une sieste en attendant."
        case .heroique: message = "Le heros entre en meditation profonde ! Aucune distraction ne passera !"
        }

        appState.messages.append(Message(role: .assistant, content: message))
    }

    // MARK: - /pause

    private static func executePause(appState: AppState) {
        appState.mochi.emotion = .sleeping

        let message: String
        switch appState.currentPersonality {
        case .kawaii: message = "Pause ! Repose-toi bien~ Je t'attends ici !"
        case .sensei: message = "Pause accordee. Mais ne t'absente pas trop longtemps."
        case .pote: message = "Pause ! Va prendre un cafe ou un truc."
        case .butler: message = "Bien, Monsieur. Je suspends le suivi. A votre retour."
        case .coach: message = "PAUSE ! Hydrate-toi, etire-toi, et on repart !"
        case .sage: message = "Meme le plus grand guerrier a besoin de repos."
        case .chat: message = "Pause ? Moi aussi, tiens."
        case .heroique: message = "Le heros fait halte au campement. Les quetes attendront son retour !"
        }

        appState.messages.append(Message(role: .assistant, content: message))
    }

    // MARK: - /objectif

    private static func executeObjectif(arguments: String?, appState: AppState) async {
        let goals = appState.memoryService.loadGoals()

        if let newGoal = arguments, !newGoal.isEmpty {
            var updatedGoals = goals
            updatedGoals.append(newGoal)
            appState.memoryService.saveGoals(updatedGoals)
            appState.messages.append(Message(
                role: .assistant,
                content: "Nouvel objectif ajoute : \"\(newGoal)\""
            ))
            return
        }

        if goals.isEmpty {
            appState.messages.append(Message(
                role: .assistant,
                content: "Tu n'as pas encore d'objectifs. Utilise `/objectif [texte]` pour en creer un."
            ))
        } else {
            var text = "Tes objectifs :\n"
            for (index, goal) in goals.enumerated() {
                text += "\(index + 1). \(goal)\n"
            }
            appState.messages.append(Message(role: .assistant, content: text))
        }
    }

    // MARK: - /humeur

    private static func executeHumeur(appState: AppState) {
        var text = "Personnalites disponibles :\n\n"
        for personality in Personality.allCases {
            let current = personality == appState.currentPersonality ? " (actuelle)" : ""
            text += "\(personality.emoji) **\(personality.displayName)**\(current)\n"
            text += "   \(personality.description)\n\n"
        }
        text += "Pour changer, dis-moi simplement quelle personnalite tu veux !"

        appState.messages.append(Message(role: .assistant, content: text))
    }

    // MARK: - /inventaire

    private static func executeInventaire(appState: AppState) {
        let items = appState.memoryService.loadInventory()
        let owned = items.filter { $0.isOwned }

        if owned.isEmpty {
            appState.messages.append(Message(
                role: .assistant,
                content: "Ton inventaire est vide. Complete des taches pour gagner des grains de riz et acheter des items dans la /boutique !"
            ))
            return
        }

        var text = "Ton inventaire :\n\n"
        for category in ItemCategory.allCases {
            let categoryItems = owned.filter { $0.category == category }
            if !categoryItems.isEmpty {
                text += "**\(category.displayName)** :\n"
                for item in categoryItems {
                    let equipped = item.isEquipped ? " [equipe]" : ""
                    text += "  - \(item.name)\(equipped)\n"
                }
                text += "\n"
            }
        }

        appState.messages.append(Message(role: .assistant, content: text))
    }

    // MARK: - /boutique

    private static func executeBoutique(appState: AppState) {
        let shopItems = defaultShopItems()
        let balance = appState.gamification.riceGrains
        let level = appState.gamification.level

        var text = "Boutique | Tes grains de riz : \(balance)\n\n"

        for category in ItemCategory.allCases {
            let categoryItems = shopItems.filter { $0.category == category }
            if !categoryItems.isEmpty {
                text += "**\(category.displayName)** :\n"
                for item in categoryItems {
                    let canAfford = balance >= item.price
                    let levelOk = level >= item.requiredLevel
                    let status: String
                    if item.isOwned {
                        status = "[possede]"
                    } else if !levelOk {
                        status = "[niveau \(item.requiredLevel) requis]"
                    } else if !canAfford {
                        status = "[fonds insuffisants]"
                    } else {
                        status = "[disponible]"
                    }
                    text += "  - \(item.name) — \(item.price) grains de riz \(status)\n"
                }
                text += "\n"
            }
        }

        appState.messages.append(Message(role: .assistant, content: text))
    }

    // MARK: - /stats

    private static func executeStats(appState: AppState) {
        let g = appState.gamification
        let totalCompleted = appState.tasks.filter { $0.isCompleted }.count
        let completedToday = appState.tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }.count

        var text = "Statistiques :\n\n"
        text += "**Niveau** : \(g.level)\n"
        text += "**XP** : \(g.currentXP)/\(g.xpRequiredForCurrentLevel)\n"
        text += "**XP total** : \(g.totalXP)\n"
        text += "**Grains de riz** : \(g.riceGrains)\n"
        text += "**Streak** : \(g.streakDays) jour(s)\n\n"
        text += "**Taches completees aujourd'hui** : \(completedToday)\n"
        text += "**Total taches completees** : \(totalCompleted)\n"

        appState.messages.append(Message(role: .assistant, content: text))
    }

    // MARK: - /notion

    private static func executeNotion(appState: AppState) async {
        appState.messages.append(Message(
            role: .assistant,
            content: "Synchronisation Notion non configuree. Utilise les reglages pour connecter ton workspace Notion."
        ))
    }

    // MARK: - /settings

    private static func executeSettings(appState: AppState) {
        appState.selectedTab = .chat // Settings is opened via the window
        appState.messages.append(Message(
            role: .assistant,
            content: "Ouvre les reglages avec Cmd+, ou via le menu de l'application."
        ))
    }

    // MARK: - /help

    private static func executeHelp(appState: AppState) {
        var text = "Commandes disponibles :\n\n"

        for command in SlashCommand.allKnown {
            text += "**\(command.displayName)** — \(command.description)\n"
        }

        text += "\nTu peux aussi ecrire en langage naturel, je comprendrai !"

        appState.messages.append(Message(role: .assistant, content: text))
    }

    // MARK: - /end

    private static func executeEnd(appState: AppState) {
        appState.memoryService.saveSession(messages: appState.messages)
        appState.saveState()

        let message: String
        switch appState.currentPersonality {
        case .kawaii: message = "Session sauvegardee ! A bientot~ Repose-toi bien !"
        case .sensei: message = "Session terminee et sauvegardee. Bon travail."
        case .pote: message = "C'est enregistre. A plus !"
        case .butler: message = "Session sauvegardee, Monsieur. Au plaisir de vous revoir."
        case .coach: message = "BONNE SESSION ! Tout est sauvegarde. A demain pour tout donner !"
        case .sage: message = "Le chapitre du jour se referme. Tout est consigne."
        case .chat: message = "Bon, c'est fini ? J'ai sauvegarde. Salut."
        case .heroique: message = "Le chroniqueur consigne les exploits du jour. A la prochaine aventure !"
        }

        appState.messages.append(Message(role: .assistant, content: message))
    }

    // MARK: - Unknown (send to Claude Code)

    private static func executeUnknown(rawInput: String, appState: AppState) async {
        let context = ClaudeCodeContext(
            personality: appState.currentPersonality,
            tasks: appState.tasks,
            gamification: appState.gamification,
            mochiName: appState.mochi.name
        )

        do {
            let response = try await appState.claudeCodeService.send(
                message: rawInput,
                personality: appState.currentPersonality,
                context: context
            )
            appState.messages.append(Message(role: .assistant, content: response))
        } catch {
            appState.messages.append(Message(
                role: .assistant,
                content: appState.currentPersonality.errorMessage
            ))
        }
    }

    // MARK: - Default Shop Items

    private static func defaultShopItems() -> [ShopItem] {
        [
            ShopItem(name: "Rose", category: .color, price: 10),
            ShopItem(name: "Matcha", category: .color, price: 10),
            ShopItem(name: "Bleu ciel", category: .color, price: 10),
            ShopItem(name: "Dore", category: .color, price: 50, requiredLevel: 10),
            ShopItem(name: "Beret", category: .hat, price: 20),
            ShopItem(name: "Couronne", category: .hat, price: 80, requiredLevel: 15),
            ShopItem(name: "Casquette", category: .hat, price: 15),
            ShopItem(name: "Chapeau de sorcier", category: .hat, price: 60, requiredLevel: 10),
            ShopItem(name: "Bandeau ninja", category: .hat, price: 40, requiredLevel: 5),
            ShopItem(name: "Lunettes", category: .accessory, price: 15),
            ShopItem(name: "Echarpe", category: .accessory, price: 20),
            ShopItem(name: "Noeud papillon", category: .accessory, price: 25),
            ShopItem(name: "Cape", category: .accessory, price: 70, requiredLevel: 12),
            ShopItem(name: "Ailes", category: .accessory, price: 100, requiredLevel: 20),
            ShopItem(name: "Jardin zen", category: .background, price: 100, requiredLevel: 5),
            ShopItem(name: "Bureau cosy", category: .background, price: 80),
            ShopItem(name: "Espace", category: .background, price: 150, requiredLevel: 15),
            ShopItem(name: "Foret de bambous", category: .background, price: 120, requiredLevel: 10),
        ]
    }
}
