import Foundation
import UserNotifications

// MARK: - Errors

enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "L'autorisation de notifications a ete refusee."
        case .schedulingFailed(let message):
            return "Echec de planification de la notification: \(message)"
        }
    }
}

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// Afficher les notifications meme quand l'app est au premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Gerer le tap sur une notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Notification Service

final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let delegate = NotificationDelegate()

    init() {
        center.delegate = delegate
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let settings = await center.notificationSettings()
            NSLog("[Mochi Notifications] Permission granted: \(granted)")
            NSLog("[Mochi Notifications] Authorization status: \(settings.authorizationStatus.rawValue)")
            NSLog("[Mochi Notifications] Alert setting: \(settings.alertSetting.rawValue)")
            return granted
        } catch {
            NSLog("[Mochi Notifications] Permission error: \(error)")
            return false
        }
    }

    func checkCurrentStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Test

    func sendTestNotification(personality: Personality) {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) \(personality.displayName)"
        content.body = personality.idleMessages.randomElement() ?? "Test de notification"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                NSLog("[Mochi Notifications] Test notification FAILED: \(error)")
            } else {
                NSLog("[Mochi Notifications] Test notification scheduled OK (3s)")
            }
        }
    }

    // MARK: - Task Reminder (single consolidated notification)

    func scheduleTaskReminder(message: String, personality: Personality, frequency: String = "normal") {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) \(personality.displayName)"
        content.body = message
        content.sound = .default

        let interval: TimeInterval
        switch frequency {
        case "intense": interval = 900    // 15 min
        case "normal":  interval = 3600   // 1h
        case "zen":     interval = 7200   // 2h
        default:        interval = 3600
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelTaskReminder() {
        cancelNotification(identifier: "task-reminder")
    }

    // MARK: - Deadline Warning

    func scheduleDeadlineWarning(for task: MochiTask, personality: Personality) {
        guard let deadline = task.deadline else { return }

        let warningDate = deadline.addingTimeInterval(-24 * 3600) // 24h before
        guard warningDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) Deadline proche !"
        content.body = deadlineWarningMessage(for: task, personality: personality)
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: warningDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "deadline-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Streak Warning

    func scheduleStreakWarning(streakDays: Int, personality: Personality) {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) Streak en danger !"
        content.body = streakWarningMessage(streakDays: streakDays, personality: personality)
        content.sound = .default

        // Schedule for 22:00 today
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak-warning-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Morning Briefing

    func scheduleMorningBriefing(at hour: Int, personality: Personality) {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) \(personality.displayName)"
        content.body = morningBriefingMessage(personality: personality)
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "morning-briefing",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Meeting Proposal

    func sendMeetingProposalNotification(count: Int, personality: Personality) {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) Nouvelles reunions detectees"
        content.body = meetingProposalMessage(count: count, personality: personality)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meeting-proposal-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Message Builders

    private func taskReminderMessage(for task: MochiTask, personality: Personality) -> String {
        switch personality {
        case .kawaii: return "N'oublie pas ta tache : \(task.title) ~ Tu peux le faire !"
        case .sensei: return "La tache \"\(task.title)\" attend. Ne la laisse pas trainer."
        case .pote: return "Eh, t'as pas oublie \"\(task.title)\" quand meme ?"
        case .butler: return "Monsieur, puis-je vous rappeler la tache \"\(task.title)\" ?"
        case .coach: return "ALLEZ ! La tache \"\(task.title)\" t'attend, on y va !"
        case .voyante: return "Les cartes me revelent une tache en suspens : \"\(task.title)\"..."
        case .chat: return "Je daigne te rappeler : \"\(task.title)\". De rien."
        case .heroique: return "Une quete reste inachevee : \"\(task.title)\" !"
        }
    }

    private func deadlineWarningMessage(for task: MochiTask, personality: Personality) -> String {
        switch personality {
        case .kawaii: return "La deadline pour \"\(task.title)\" approche ! Courage~"
        case .sensei: return "Deadline imminente pour \"\(task.title)\". Pas de place pour le retard."
        case .pote: return "Deadline demain pour \"\(task.title)\". Tu geres ou je stresse ?"
        case .butler: return "La deadline pour \"\(task.title)\" est demain, Monsieur."
        case .coach: return "DEADLINE DEMAIN pour \"\(task.title)\" ! On sprint !"
        case .voyante: return "Les astres m'avertissent : la deadline pour \"\(task.title)\" approche a grands pas..."
        case .chat: return "Ta deadline pour \"\(task.title)\" est demain. Pas mon probleme."
        case .heroique: return "Le temps est compte pour la quete \"\(task.title)\" ! L'aube approche !"
        }
    }

    private func streakWarningMessage(streakDays: Int, personality: Personality) -> String {
        switch personality {
        case .kawaii: return "Ton streak de \(streakDays) jours est en danger ! Complete une tache vite~"
        case .sensei: return "\(streakDays) jours de streak. Ne laisse pas tomber maintenant."
        case .pote: return "Il te reste 2h pour garder ton streak de \(streakDays) jours !"
        case .butler: return "Votre streak de \(streakDays) jours risque de s'interrompre, Monsieur."
        case .coach: return "STREAK DE \(streakDays) JOURS EN DANGER ! Une tache et c'est bon, GO !"
        case .voyante: return "Les energies cosmiques tremblent ! Ton streak de \(streakDays) jours risque de s'eteindre..."
        case .chat: return "\(streakDays) jours de streak. Ca serait dommage. Enfin, pour toi."
        case .heroique: return "Le heros risque de perdre sa serie de \(streakDays) victoires ! Agis vite !"
        }
    }

    private func meetingProposalMessage(count: Int, personality: Personality) -> String {
        let s = count > 1 ? "s" : ""
        switch personality {
        case .kawaii: return "\(count) reunion\(s) avec des taches a valider~ Viens voir !"
        case .sensei: return "\(count) reunion\(s) detectee\(s). Des taches t'attendent. Agis."
        case .pote: return "Eh ! \(count) reunion\(s) avec des trucs a faire. Check ca !"
        case .butler: return "Monsieur, \(count) reunion\(s) requierent votre attention."
        case .coach: return "\(count) REUNION\(s.uppercased()) ! Des taches a valider, GO !"
        case .voyante: return "Les astres revelent \(count) reunion\(s)... Des taches emergent des etoiles."
        case .chat: return "\(count) reunion\(s). Des taches. Tu devrais regarder. Ou pas."
        case .heroique: return "\(count) conseil\(s) de guerre detecte\(s) ! De nouvelles quetes t'attendent !"
        }
    }

    private func morningBriefingMessage(personality: Personality) -> String {
        switch personality {
        case .kawaii: return "Ohayo ! Viens voir tes taches du jour~"
        case .sensei: return "Nouvelle journee, nouveaux defis. Ouvre l'app."
        case .pote: return "Salut ! On regarde ce qu'on a aujourd'hui ?"
        case .butler: return "Bonjour Monsieur. Votre programme du jour vous attend."
        case .coach: return "DEBOUT ! C'est l'heure de tout defoncer aujourd'hui !"
        case .voyante: return "Les astres annoncent une journee riche en revelations. Viens decouvrir ton destin..."
        case .chat: return "Tu es reveille ? Bon. Viens voir tes taches."
        case .heroique: return "L'aube se leve sur un nouveau chapitre ! Tes quetes t'attendent !"
        }
    }
}
