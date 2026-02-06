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
    @Published var isLoading: Bool = false
    @Published var selectedTab: AppTab = .chat

    // MARK: - Services

    let claudeCodeService: ClaudeCodeService
    let memoryService: MemoryService
    let notificationService: NotificationService

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
        }

        if let mochiState = memoryService.loadMochiState() {
            self.gamification = mochiState
        }

        self.tasks = memoryService.loadTasks()
        self.mochi.updateEmotion(from: gamification, tasks: tasks)
    }

    func saveState() {
        memoryService.saveMochiState(gamification)
        memoryService.saveTasks(tasks)
    }

    // MARK: - Chat

    func sendMessage(_ text: String) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        mochi.emotion = .thinking

        defer {
            isLoading = false
            mochi.updateEmotion(from: gamification, tasks: tasks)
        }

        // Check for slash commands
        if text.hasPrefix("/") {
            let result = SlashCommandParser.parse(text)
            await CommandEngine.execute(result, appState: self)
            return
        }

        // Send to Claude Code
        do {
            let response = try await claudeCodeService.send(
                message: text,
                personality: currentPersonality,
                context: buildContext()
            )
            let assistantMessage = Message(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            let errorMessage = Message(
                role: .assistant,
                content: currentPersonality.errorMessage
            )
            messages.append(errorMessage)
        }

        saveState()
    }

    // MARK: - Tasks

    func completeTask(_ task: MochiTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = true
        tasks[index].completedAt = Date()

        let rewards = gamification.rewardForTask(task)
        gamification.applyRewards(rewards)

        mochi.emotion = .happy
        saveState()
    }

    func addTask(_ task: MochiTask) {
        tasks.append(task)
        saveState()
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

// MARK: - App Tab

enum AppTab: String, CaseIterable {
    case chat = "Chat"
    case dashboard = "Dashboard"
}
