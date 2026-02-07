import SwiftUI
import Combine
import PDFKit

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published State

    @Published var mochi: MochiCharacter
    @Published var messages: [Message] = []
    @Published var tasks: [MochiTask] = []
    @Published var gamification: GamificationState
    @Published var currentPersonality: Personality = .kawaii
    @Published var isOnboardingComplete: Bool = false
    @Published var inventory: [ShopItem] = []
    @Published var isLoading: Bool = false
    @Published var selectedTab: AppTab = .dashboard
    @Published var selectedSettingsTab: Int = 0
    @Published var notificationsBlocked: Bool = false
    @Published var userName: String = ""
    @Published var userOccupation: String = ""
    @Published var userGoal: String = ""
    @Published var notificationFrequency: String = "normal"
    @Published var morningBriefingEnabled: Bool = true
    @Published var morningBriefingHour: Int = 9
    @Published var weekendsProtected: Bool = false
    @Published var globalShortcut: String = "⌘⇧M"
    @Published var daysOff: [Int] = []

    // MARK: - Notion & Meetings
    @Published var isNotionConnected: Bool = false
    @Published var isCheckingNotion: Bool = false
    @Published var meetingWatchEnabled: Bool = false
    @Published var meetingCheckInterval: Int = 30
    @Published var meetingLookbackDays: Int = 7
    @Published var meetingProposals: [MeetingProposal] = []
    @Published var isCheckingMeetings: Bool = false
    @Published var meetingCheckResult: String?

    // MARK: - Speech (forwarded from SpeechService)

    @Published var isRecordingVoice: Bool = false
    @Published var voiceTranscription: String = ""

    // MARK: - Services

    let claudeCodeService: ClaudeCodeService
    let memoryService: MemoryService
    let notificationService: NotificationService
    let speechService: SpeechService

    // MARK: - Emotion Timer
    private var emotionResetTask: Task<Void, Never>?
    private var meetingWatchTask: Task<Void, Never>?
    private var speechCancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        self.mochi = MochiCharacter()
        self.gamification = GamificationState()
        self.claudeCodeService = ClaudeCodeService()
        self.memoryService = MemoryService()
        self.notificationService = NotificationService()
        self.speechService = SpeechService()

        // Forward SpeechService published properties so SwiftUI observes them
        speechService.$isRecording
            .receive(on: RunLoop.main)
            .assign(to: &$isRecordingVoice)
        speechService.$transcribedText
            .receive(on: RunLoop.main)
            .assign(to: &$voiceTranscription)

        // Mochi reacts to voice recording
        speechService.$isRecording
            .receive(on: RunLoop.main)
            .sink { [weak self] isRecording in
                guard let self else { return }
                if isRecording {
                    self.mochi.emotion = .listening
                } else if self.mochi.emotion == .listening {
                    self.mochi.updateEmotion(from: self.gamification, tasks: self.tasks)
                }
            }
            .store(in: &speechCancellables)

        loadState()
    }

    // MARK: - State Management

    func loadState() {
        if let config = memoryService.loadConfig() {
            self.currentPersonality = config.personality
            self.isOnboardingComplete = config.isOnboardingComplete
            self.mochi.name = config.mochiName
            self.mochi.color = config.mochiColor
            self.userName = config.userName
            self.userOccupation = config.userOccupation
            self.userGoal = config.userGoal
            self.notificationFrequency = config.notificationFrequency
            self.morningBriefingEnabled = config.morningBriefingEnabled
            self.morningBriefingHour = config.morningBriefingHour
            self.weekendsProtected = config.weekendsProtected
            self.globalShortcut = config.globalShortcut
            self.daysOff = config.daysOff
            self.meetingWatchEnabled = config.meetingWatchEnabled
            self.meetingCheckInterval = config.meetingCheckInterval
            self.meetingLookbackDays = config.meetingLookbackDays
        }

        if let mochiState = memoryService.loadMochiState() {
            self.gamification = mochiState
        }

        self.tasks = memoryService.loadTasks()
        self.inventory = memoryService.loadInventory()
        self.meetingProposals = memoryService.loadMeetingProposals()
        self.mochi.updateEmotion(from: gamification, tasks: tasks)
        updateClaudeMd()

        if meetingWatchEnabled {
            startMeetingWatch()
        }
    }

    func saveConfig() {
        let config = AppConfig(
            mochiName: mochi.name,
            personality: currentPersonality,
            mochiColor: mochi.color,
            isOnboardingComplete: isOnboardingComplete,
            userName: userName,
            userOccupation: userOccupation,
            userGoal: userGoal,
            notificationFrequency: notificationFrequency,
            morningBriefingEnabled: morningBriefingEnabled,
            morningBriefingHour: morningBriefingHour,
            weekendsProtected: weekendsProtected,
            globalShortcut: globalShortcut,
            daysOff: daysOff,
            meetingWatchEnabled: meetingWatchEnabled,
            meetingCheckInterval: meetingCheckInterval,
            meetingLookbackDays: meetingLookbackDays
        )
        memoryService.saveConfig(config)
    }

    func saveState() {
        saveConfig()
        memoryService.saveMochiState(gamification)
        memoryService.saveTasks(tasks)
        memoryService.saveInventory(inventory)
        memoryService.saveMeetingProposals(meetingProposals)
        updateClaudeMd()
    }

    /// Storage directory where CLAUDE.md lives and where Claude Code is launched
    var storageDirectory: URL {
        memoryService.storage.baseDirectory
    }

    /// Write/update the CLAUDE.md file so Claude Code reads context automatically
    func updateClaudeMd() {
        let context = buildContext()
        let content = context.buildClaudeMd()
        try? memoryService.storage.write(file: "CLAUDE.md", content: content)
    }

    // MARK: - Notifications

    func setupNotifications() async {
        let status = await notificationService.checkCurrentStatus()

        if status == .notDetermined {
            // First time: try requesting permission
            let granted = await notificationService.requestPermission()
            if granted {
                NSLog("[Mochi] Notification permission granted")
                rescheduleAllNotifications()
                notificationService.sendTestNotification(personality: currentPersonality)
                return
            }
        }

        if status == .authorized || status == .provisional {
            NSLog("[Mochi] Notifications already authorized")
            rescheduleAllNotifications()
            return
        }

        // Permission denied or not determined after request — open System Settings
        NSLog("[Mochi] Notification permission denied (status: %d) — opening System Settings", status.rawValue)
        notificationsBlocked = true
    }

    func refreshNotificationStatus() async {
        let status = await notificationService.checkCurrentStatus()
        notificationsBlocked = (status != .authorized && status != .provisional)
        if !notificationsBlocked {
            NSLog("[Mochi] Notifications now authorized — rescheduling")
            rescheduleAllNotifications()
        }
    }

    func rescheduleAllNotifications() {
        notificationService.cancelAll()

        // Morning briefing
        if morningBriefingEnabled {
            notificationService.scheduleMorningBriefing(
                at: morningBriefingHour,
                personality: currentPersonality
            )
        }

        // Streak warning (si streak active)
        if gamification.streakDays > 0 {
            notificationService.scheduleStreakWarning(
                streakDays: gamification.streakDays,
                personality: currentPersonality
            )
        }

        // Re-schedule reminders pour les taches en cours
        let activeTasks = tasks.filter { !$0.isCompleted }

        // Deadline warnings restent individuels (dates différentes)
        for task in activeTasks {
            notificationService.scheduleDeadlineWarning(
                for: task,
                personality: currentPersonality
            )
        }

        // Notification consolidée via Claude Code (async, fire-and-forget)
        if notificationFrequency != "zen" && !activeTasks.isEmpty {
            let personality = currentPersonality
            let frequency = notificationFrequency
            let taskTitles = activeTasks.map { $0.title }
            Task {
                await generateAndScheduleTaskNotification(
                    taskTitles: taskTitles,
                    personality: personality,
                    frequency: frequency
                )
            }
        }
    }

    private func generateAndScheduleTaskNotification(
        taskTitles: [String],
        personality: Personality,
        frequency: String
    ) async {
        let taskList = taskTitles.map { "- \($0)" }.joined(separator: "\n")
        let prompt = """
        Tu es \(personality.displayName). \(personality.systemPrompt)
        Voici les tâches en cours de l'utilisateur :
        \(taskList)
        Génère UNE SEULE phrase courte (max 80 caractères) pour rappeler ces tâches. \
        Adopte le ton de ta personnalité. Réponds UNIQUEMENT avec la phrase, rien d'autre.
        """

        var message: String
        do {
            message = try await claudeCodeService.generateQuick(prompt: prompt)
            // Nettoyer les guillemets éventuels
            message = message.trimmingCharacters(in: CharacterSet(charactersIn: "\"'\u{201C}\u{201D}\u{2018}\u{2019}"))
        } catch {
            // Fallback : message simple avec une tâche au hasard
            let randomTitle = taskTitles.randomElement() ?? "tes tâches"
            message = "N'oublie pas : \(randomTitle)"
            NSLog("[Mochi Notifications] Claude Code fallback: \(error.localizedDescription)")
        }

        notificationService.scheduleTaskReminder(
            message: message,
            personality: personality,
            frequency: frequency
        )
    }

    // MARK: - Auto Greeting

    @Published var hasGreetedThisSession: Bool = false

    func sendSilentGreeting() async {
        guard !hasGreetedThisSession else { return }
        hasGreetedThisSession = true
        isLoading = true
        setTemporaryEmotion(.happy)

        let result = SlashCommandParser.parse("/bonjour")
        await CommandEngine.execute(result, appState: self)
        isLoading = false
        if let lastMessage = messages.last, lastMessage.role == .assistant {
            setReactiveEmotion(from: lastMessage.content)
        }
    }

    // MARK: - Chat

    func sendMessage(_ text: String, attachments: [Attachment] = []) async {
        let userMessage = Message(role: .user, content: text, attachments: attachments)
        messages.append(userMessage)
        isLoading = true
        setTemporaryEmotion(.writing)

        // Check for slash commands
        if text.hasPrefix("/") {
            let result = SlashCommandParser.parse(text)
            await CommandEngine.execute(result, appState: self)
            isLoading = false
            if let lastMessage = messages.last, lastMessage.role == .assistant {
                setReactiveEmotion(from: lastMessage.content)
            }
            saveState()
            return
        }

        // Detect natural language task creation
        if let taskTitle = extractTaskFromNaturalLanguage(text) {
            isLoading = false
            let task = MochiTask(title: taskTitle)
            addTask(task)
            let confirmation = "C'est note ! J'ai ajoute la tache \"\(taskTitle)\" a ta liste."
            messages.append(Message(role: .assistant, content: confirmation))
            setTemporaryEmotion(.happy, duration: 3)
            saveState()
            return
        }

        // Build enriched prompt with attachment contents
        let enrichedMessage = buildEnrichedMessage(text, attachments: attachments)

        // Send to Claude Code
        do {
            updateClaudeMd()
            let response = try await claudeCodeService.send(
                message: enrichedMessage,
                workingDirectory: storageDirectory
            )
            isLoading = false

            // Parse task markers from response and create real tasks
            let (cleanResponse, newTasks) = parseTaskMarkers(from: response)
            for task in newTasks {
                addTask(task)
            }

            let assistantMessage = Message(role: .assistant, content: cleanResponse)
            messages.append(assistantMessage)
            setReactiveEmotion(from: cleanResponse)
        } catch {
            isLoading = false
            let errorMessage = Message(
                role: .assistant,
                content: currentPersonality.errorMessage
            )
            messages.append(errorMessage)
            setTemporaryEmotion(.worried, duration: 4)
        }

        saveState()
    }

    private func buildEnrichedMessage(_ text: String, attachments: [Attachment]) -> String {
        guard !attachments.isEmpty else { return text }

        var parts: [String] = []
        if !text.isEmpty {
            parts.append(text)
        }

        for attachment in attachments {
            let fullPath = memoryService.storage.baseDirectory
                .appendingPathComponent(attachment.filePath).path

            if attachment.isPDF {
                if let pdfText = extractPDFText(at: fullPath) {
                    parts.append("[Fichier joint : \(attachment.fileName)]\n```\n\(pdfText)\n```")
                } else {
                    parts.append("[Fichier joint : \(attachment.fileName)] (PDF non lisible)")
                }
            } else if attachment.isTextReadable {
                if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                    parts.append("[Fichier joint : \(attachment.fileName)]\n```\n\(content)\n```")
                } else {
                    parts.append("[Fichier joint : \(attachment.fileName)] (lecture impossible)")
                }
            } else {
                parts.append("[Fichier joint : \(attachment.fileName)] (fichier binaire, chemin: \(fullPath))")
            }
        }

        return parts.joined(separator: "\n\n")
    }

    private func extractPDFText(at path: String) -> String? {
        guard let pdfDoc = PDFDocument(url: URL(fileURLWithPath: path)) else { return nil }
        var text = ""
        for i in 0..<pdfDoc.pageCount {
            if let page = pdfDoc.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
        }
        return text.isEmpty ? nil : text
    }

    // MARK: - Emotion Management

    /// Set an emotion that reacts to content, then fades back to baseline after a delay
    func setReactiveEmotion(from content: String) {
        mochi.reactToResponse(content)
        scheduleEmotionReset(after: 6)
    }

    /// Set a temporary emotion for a specific duration
    func setTemporaryEmotion(_ emotion: MochiEmotion, duration: TimeInterval = 0) {
        mochi.emotion = emotion
        if duration > 0 {
            scheduleEmotionReset(after: duration)
        }
    }

    private func scheduleEmotionReset(after seconds: TimeInterval) {
        emotionResetTask?.cancel()
        emotionResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            mochi.updateEmotion(from: gamification, tasks: tasks)
        }
    }

    // MARK: - Tasks

    func completeTask(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }),
              !tasks[index].isCompleted else { return }
        tasks[index].isCompleted = true
        tasks[index].completedAt = Date()

        // Annuler les notifications de cette tache
        notificationService.cancelNotification(identifier: "deadline-\(task.id.uuidString)")
        // Reprogrammer la notification consolidée sans cette tâche
        rescheduleAllNotifications()

        let rewards = gamification.rewardForTask(task)
        let leveledUp = gamification.applyRewards(rewards)

        // React based on achievement
        if leveledUp {
            setTemporaryEmotion(.excited, duration: 8)
        } else {
            setTemporaryEmotion(.happy, duration: 5)
        }
        saveState()
    }

    func addTask(_ task: MochiTask) {
        tasks.append(task)

        // Reprogrammer les notifications avec la nouvelle tâche incluse
        rescheduleAllNotifications()

        saveState()
    }

    func updateTask(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].title = task.title
        tasks[index].description = task.description
        tasks[index].priority = task.priority
        tasks[index].deadline = task.deadline
        saveState()
    }

    func deleteTask(_ task: MochiTask) {
        notificationService.cancelNotification(identifier: "deadline-\(task.id.uuidString)")
        tasks.removeAll { $0.id == task.id }
        // Reprogrammer la notification consolidée sans cette tâche
        rescheduleAllNotifications()
        saveState()
    }

    func toggleInProgress(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isInProgress.toggle()
        saveState()
    }

    func toggleTracked(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isTracked.toggle()
        // Reprogrammer la notification consolidée
        rescheduleAllNotifications()
        saveState()
    }

    // MARK: - Shop

    func purchaseItem(_ item: ShopItem) {
        guard gamification.riceGrains >= item.price else { return }
        guard gamification.level >= item.requiredLevel else { return }
        guard !isItemOwned(name: item.name, category: item.category) else { return }

        gamification.riceGrains -= item.price
        var purchased = item
        purchased.isOwned = true
        inventory.append(purchased)
        saveState()
    }

    func equipColor(_ colorName: String) {
        guard let mochiColor = MochiColor.allCases.first(where: { $0.displayName == colorName }) else { return }
        guard mochiColor.isUnlocked(at: gamification.level) else { return }
        mochi.color = mochiColor
        saveState()
    }

    func equipItem(_ item: ShopItem) {
        // Unequip all items of same category, then equip this one
        for i in inventory.indices {
            if inventory[i].category == item.category {
                inventory[i].isEquipped = (inventory[i].name == item.name)
            }
        }
        // Update equipped items on mochi
        mochi.equippedItems = inventory.filter { $0.isEquipped && $0.category != .color }
        saveState()
    }

    func unequipItem(_ item: ShopItem) {
        for i in inventory.indices {
            if inventory[i].name == item.name && inventory[i].category == item.category {
                inventory[i].isEquipped = false
            }
        }
        mochi.equippedItems = inventory.filter { $0.isEquipped && $0.category != .color }
        saveState()
    }

    func isItemOwned(name: String, category: ItemCategory) -> Bool {
        inventory.contains { $0.name == name && $0.category == category && $0.isOwned }
    }

    // MARK: - Notion Connectivity

    func checkNotionConnectivity() async {
        isCheckingNotion = true
        defer { isCheckingNotion = false }

        let prompt = """
        Utilise l'outil MCP Notion notion-search pour faire une recherche simple \
        avec le mot-cle "test". \
        Si tu arrives a te connecter a Notion et obtenir un resultat (meme vide), \
        reponds exactement : NOTION_OK \
        Si tu n'arrives pas a te connecter ou si l'outil MCP n'est pas disponible, \
        reponds exactement : NOTION_ERROR
        """

        do {
            let response = try await claudeCodeService.generateQuick(
                prompt: prompt,
                workingDirectory: storageDirectory
            )
            isNotionConnected = response.contains("NOTION_OK")
            NSLog("[Mochi Notion] Connectivity check: %@", isNotionConnected ? "OK" : "FAILED")
        } catch {
            isNotionConnected = false
            NSLog("[Mochi Notion] Connectivity check error: %@", error.localizedDescription)
        }
    }

    // MARK: - Meeting Watch

    func startMeetingWatch() {
        stopMeetingWatch()
        guard meetingWatchEnabled else { return }
        meetingWatchTask = Task { @MainActor in
            while !Task.isCancelled {
                await checkForNewMeetings()
                let seconds = UInt64(meetingCheckInterval) * 60
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            }
        }
        NSLog("[Mochi Meetings] Watch started (interval: %d min)", meetingCheckInterval)
    }

    func stopMeetingWatch() {
        meetingWatchTask?.cancel()
        meetingWatchTask = nil
        NSLog("[Mochi Meetings] Watch stopped")
    }

    func checkForNewMeetings() async {
        isCheckingMeetings = true
        meetingCheckResult = nil

        let existingIds = Set(meetingProposals.map { $0.meetingNotionId })
        let idsString = existingIds.isEmpty ? "aucun" : existingIds.joined(separator: ", ")

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -meetingLookbackDays, to: Date()) ?? Date()
        let cutoffString = ISO8601DateFormatter().string(from: cutoffDate)

        let prompt = """
        Utilise les outils MCP Notion (notion-search, notion-fetch) pour chercher des pages \
        de reunions ou meetings recents dans le workspace Notion de l'utilisateur. \
        Cherche avec des mots-cles comme "reunion", "meeting", "compte-rendu", "CR".

        Ne remonte pas plus loin que \(meetingLookbackDays) jours (apres le \(cutoffString)).

        IDs de pages deja traitees a ignorer : \(idsString)

        Pour chaque nouvelle reunion trouvee, analyse le contenu et propose des taches \
        concretes et actionnables.

        Reponds UNIQUEMENT en JSON valide (pas de markdown, pas de commentaires) :
        [{"notionPageId":"...","title":"...","date":"2025-01-15","suggestedTasks":[{"title":"...","priority":"normal","description":"..."}]}]

        Si aucune nouvelle reunion, reponds : []
        """

        do {
            let response = try await claudeCodeService.generateQuick(
                prompt: prompt,
                workingDirectory: storageDirectory
            )
            let parsed = parseMeetingResponse(response)
            let newProposals = parsed.filter { p in !existingIds.contains(p.meetingNotionId) }
            if !newProposals.isEmpty {
                meetingProposals.insert(contentsOf: newProposals, at: 0)
                notificationService.sendMeetingProposalNotification(
                    count: newProposals.count,
                    personality: currentPersonality
                )
                memoryService.saveMeetingProposals(meetingProposals)
                let s = newProposals.count > 1 ? "s" : ""
                meetingCheckResult = "\(newProposals.count) reunion\(s) trouvee\(s)"
                NSLog("[Mochi Meetings] %d new proposals found", newProposals.count)
            } else {
                meetingCheckResult = "Aucune nouvelle reunion"
            }
        } catch {
            meetingCheckResult = "Erreur : \(error.localizedDescription)"
            NSLog("[Mochi Meetings] Check failed: %@", error.localizedDescription)
        }

        isCheckingMeetings = false
    }

    private func parseMeetingResponse(_ response: String) -> [MeetingProposal] {
        // Try to extract JSON array from the response
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON array boundaries
        guard let startIdx = trimmed.firstIndex(of: "["),
              let endIdx = trimmed.lastIndex(of: "]") else {
            return []
        }

        let jsonString = String(trimmed[startIdx...endIdx])
        guard let data = jsonString.data(using: .utf8) else { return [] }

        struct RawMeeting: Decodable {
            let notionPageId: String
            let title: String
            let date: String?
            let suggestedTasks: [RawTask]
        }
        struct RawTask: Decodable {
            let title: String
            let priority: String?
            let description: String?
        }

        do {
            let rawMeetings = try JSONDecoder().decode([RawMeeting].self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            return rawMeetings.map { raw in
                let tasks = raw.suggestedTasks.map { rt in
                    SuggestedTask(
                        title: rt.title,
                        description: rt.description,
                        priority: TaskPriority(rawValue: rt.priority ?? "normal") ?? .normal
                    )
                }
                return MeetingProposal(
                    meetingNotionId: raw.notionPageId,
                    meetingTitle: raw.title,
                    meetingDate: raw.date.flatMap { dateFormatter.date(from: $0) },
                    suggestedTasks: tasks
                )
            }
        } catch {
            NSLog("[Mochi Meetings] JSON parse error: %@", error.localizedDescription)
            return []
        }
    }

    func acceptSuggestedTask(_ taskId: UUID, in proposalId: UUID) {
        guard let pIdx = meetingProposals.firstIndex(where: { $0.id == proposalId }),
              let tIdx = meetingProposals[pIdx].suggestedTasks.firstIndex(where: { $0.id == taskId }) else { return }

        meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted = true
        let suggested = meetingProposals[pIdx].suggestedTasks[tIdx]
        let task = MochiTask(
            title: suggested.title,
            description: suggested.description,
            priority: suggested.priority
        )
        addTask(task)
    }

    func rejectSuggestedTask(_ taskId: UUID, in proposalId: UUID) {
        guard let pIdx = meetingProposals.firstIndex(where: { $0.id == proposalId }),
              let tIdx = meetingProposals[pIdx].suggestedTasks.firstIndex(where: { $0.id == taskId }) else { return }
        meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted = false
        saveState()
    }

    func acceptAllTasks(in proposalId: UUID) {
        guard let pIdx = meetingProposals.firstIndex(where: { $0.id == proposalId }) else { return }
        for tIdx in meetingProposals[pIdx].suggestedTasks.indices {
            if meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted == nil {
                meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted = true
                let suggested = meetingProposals[pIdx].suggestedTasks[tIdx]
                let task = MochiTask(
                    title: suggested.title,
                    description: suggested.description,
                    priority: suggested.priority
                )
                tasks.append(task)
            }
        }
        meetingProposals[pIdx].status = .reviewed
        saveState()
        rescheduleAllNotifications()
    }

    func dismissProposal(_ proposalId: UUID) {
        guard let pIdx = meetingProposals.firstIndex(where: { $0.id == proposalId }) else { return }
        for tIdx in meetingProposals[pIdx].suggestedTasks.indices {
            if meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted == nil {
                meetingProposals[pIdx].suggestedTasks[tIdx].isAccepted = false
            }
        }
        meetingProposals[pIdx].status = .reviewed
        saveState()
    }

    var pendingProposalsCount: Int {
        meetingProposals.filter { $0.status == .pending }.count
    }

    // MARK: - Response Parsing

    private func parseTaskMarkers(from response: String) -> (cleanText: String, tasks: [MochiTask]) {
        var tasks: [MochiTask] = []
        var cleanLines: [String] = []

        let lines = response.components(separatedBy: "\n")
        let taskPattern = /\[TASK(?:_(HIGH|LOW))?:(.+?)\]/

        for line in lines {
            if let match = line.firstMatch(of: taskPattern) {
                let priorityStr = match.1.map { String($0) }
                let title = String(match.2).trimmingCharacters(in: .whitespaces)

                let priority: TaskPriority
                switch priorityStr {
                case "HIGH": priority = .high
                case "LOW": priority = .low
                default: priority = .normal
                }

                tasks.append(MochiTask(title: title, priority: priority))

                // Keep the line only if there's other text besides the marker
                let remainder = line.replacing(taskPattern, with: { _ in "" }).trimmingCharacters(in: .whitespaces)
                if !remainder.isEmpty {
                    cleanLines.append(remainder)
                }
            } else {
                cleanLines.append(line)
            }
        }

        let cleanText = cleanLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleanText, tasks)
    }

    /// Detect natural language task creation like "ajoute la tache faire les courses"
    private func extractTaskFromNaturalLanguage(_ text: String) -> String? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)
        let prefixes = [
            "ajoute la tache ",
            "ajoute une tache ",
            "ajoute tache ",
            "ajoute ",
            "ajouter ",
            "nouvelle tache ",
            "nouvelle tache: ",
            "note ",
            "note: ",
            "cree la tache ",
            "cree une tache ",
            "creer ",
            "tache: ",
            "tache : ",
            "task: ",
            "task ",
            "todo ",
            "todo: ",
        ]
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let title = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                if !title.isEmpty && title.count >= 3 {
                    return title
                }
            }
        }
        return nil
    }

    // MARK: - Helpers

    private func buildContext() -> ClaudeCodeContext {
        ClaudeCodeContext(
            personality: currentPersonality,
            tasks: tasks,
            gamification: gamification,
            mochiName: mochi.name,
            userName: userName,
            userOccupation: userOccupation,
            userGoal: userGoal
        )
    }
}

