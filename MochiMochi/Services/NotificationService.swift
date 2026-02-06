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

// MARK: - Notification Service

final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Task Reminders

    func scheduleTaskReminder(for task: MochiTask, personality: Personality, frequency: String = "normal") {
        let content = UNMutableNotificationContent()
        content.title = "\(personality.emoji) \(personality.displayName)"
        content.body = taskReminderMessage(for: task, personality: personality)
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]

        let interval: TimeInterval
        switch frequency {
        case "intense": interval = 900    // 15 min
        case "normal":  interval = 3600   // 1h
        case "zen":     interval = 7200   // 2h (fallback, zen ne devrait pas schedule)
        default:        interval = 3600
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-reminder-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
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
        case .sage: return "Une tache inachevee pese sur l'esprit : \"\(task.title)\"."
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
        case .sage: return "Le temps presse pour \"\(task.title)\". L'urgence n'attend pas."
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
        case .sage: return "La constance est une vertu. Ton streak de \(streakDays) jours merite d'etre preservee."
        case .chat: return "\(streakDays) jours de streak. Ca serait dommage. Enfin, pour toi."
        case .heroique: return "Le heros risque de perdre sa serie de \(streakDays) victoires ! Agis vite !"
        }
    }

    private func morningBriefingMessage(personality: Personality) -> String {
        switch personality {
        case .kawaii: return "Ohayo ! Viens voir tes taches du jour~"
        case .sensei: return "Nouvelle journee, nouveaux defis. Ouvre l'app."
        case .pote: return "Salut ! On regarde ce qu'on a aujourd'hui ?"
        case .butler: return "Bonjour Monsieur. Votre programme du jour vous attend."
        case .coach: return "DEBOUT ! C'est l'heure de tout defoncer aujourd'hui !"
        case .sage: return "Un nouveau jour se leve. Voyons ce qu'il nous reserve."
        case .chat: return "Tu es reveille ? Bon. Viens voir tes taches."
        case .heroique: return "L'aube se leve sur un nouveau chapitre ! Tes quetes t'attendent !"
        }
    }
}
