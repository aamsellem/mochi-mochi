import SwiftUI
import Combine

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
    @Published var notificationFrequency: String = "normal"
    @Published var morningBriefingEnabled: Bool = true
    @Published var morningBriefingHour: Int = 9
    @Published var weekendsProtected: Bool = false

    // MARK: - Services

    let claudeCodeService: ClaudeCodeService
    let memoryService: MemoryService
    let notificationService: NotificationService

    // MARK: - Emotion Timer
    private var emotionResetTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        self.mochi = MochiCharacter()
        self.gamification = GamificationState()
        self.claudeCodeService = ClaudeCodeService()
        self.memoryService = MemoryService()
        self.notificationService = NotificationService()

        loadState()
    }

    // MARK: - State Management

    func loadState() {
        if let config = memoryService.loadConfig() {
            self.currentPersonality = config.personality
            self.isOnboardingComplete = config.isOnboardingComplete
            self.mochi.name = config.mochiName
            self.mochi.color = config.mochiColor
            self.notificationFrequency = config.notificationFrequency
            self.morningBriefingEnabled = config.morningBriefingEnabled
            self.morningBriefingHour = config.morningBriefingHour
            self.weekendsProtected = config.weekendsProtected
        }

        if let mochiState = memoryService.loadMochiState() {
            self.gamification = mochiState
        }

        self.tasks = memoryService.loadTasks()
        self.inventory = memoryService.loadInventory()
        self.mochi.updateEmotion(from: gamification, tasks: tasks)
    }

    func saveConfig() {
        let config = AppConfig(
            mochiName: mochi.name,
            personality: currentPersonality,
            mochiColor: mochi.color,
            isOnboardingComplete: isOnboardingComplete,
            notificationFrequency: notificationFrequency,
            morningBriefingEnabled: morningBriefingEnabled,
            morningBriefingHour: morningBriefingHour,
            weekendsProtected: weekendsProtected
        )
        memoryService.saveConfig(config)
    }

    func saveState() {
        saveConfig()
        memoryService.saveMochiState(gamification)
        memoryService.saveTasks(tasks)
        memoryService.saveInventory(inventory)
    }

    // MARK: - Notifications

    func setupNotifications() async {
        let granted = await notificationService.requestPermission()
        guard granted else { return }
        rescheduleAllNotifications()
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
        for task in activeTasks {
            if notificationFrequency != "zen" {
                notificationService.scheduleTaskReminder(
                    for: task,
                    personality: currentPersonality
                )
            }
            notificationService.scheduleDeadlineWarning(
                for: task,
                personality: currentPersonality
            )
        }
    }

    // MARK: - Chat

    func sendMessage(_ text: String) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        setTemporaryEmotion(.thinking)

        // Check for slash commands
        if text.hasPrefix("/") {
            let result = SlashCommandParser.parse(text)
            isLoading = false
            await CommandEngine.execute(result, appState: self)
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

        // Send to Claude Code
        do {
            let response = try await claudeCodeService.send(
                message: text,
                personality: currentPersonality,
                context: buildContext()
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
        notificationService.cancelNotification(identifier: "task-reminder-\(task.id.uuidString)")
        notificationService.cancelNotification(identifier: "deadline-\(task.id.uuidString)")

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

        // Schedule notifications pour la nouvelle tache
        if notificationFrequency != "zen" {
            notificationService.scheduleTaskReminder(
                for: task,
                personality: currentPersonality
            )
        }
        notificationService.scheduleDeadlineWarning(
            for: task,
            personality: currentPersonality
        )

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
        notificationService.cancelNotification(identifier: "task-reminder-\(task.id.uuidString)")
        notificationService.cancelNotification(identifier: "deadline-\(task.id.uuidString)")
        tasks.removeAll { $0.id == task.id }
        saveState()
    }

    func toggleInProgress(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isInProgress.toggle()
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
            mochiName: mochi.name
        )
    }
}

