import Foundation

// MARK: - Task Rewards

struct TaskRewards {
    let xp: Int
    let riceGrains: Int
}

// MARK: - Gamification State

struct GamificationState: Codable {
    var level: Int
    var currentXP: Int
    var totalXP: Int
    var riceGrains: Int
    var streakDays: Int
    var lastActiveDate: Date?
    var todayRemainingTasks: Int

    init(
        level: Int = 1,
        currentXP: Int = 0,
        totalXP: Int = 0,
        riceGrains: Int = 0,
        streakDays: Int = 0,
        lastActiveDate: Date? = nil,
        todayRemainingTasks: Int = 0
    ) {
        self.level = level
        self.currentXP = currentXP
        self.totalXP = totalXP
        self.riceGrains = riceGrains
        self.streakDays = streakDays
        self.lastActiveDate = lastActiveDate
        self.todayRemainingTasks = todayRemainingTasks
    }

    // MARK: - XP Calculation

    var xpRequiredForCurrentLevel: Int {
        Self.xpRequired(forLevel: level)
    }

    var xpProgress: Double {
        let required = xpRequiredForCurrentLevel
        guard required > 0 else { return 0 }
        return Double(currentXP) / Double(required)
    }

    static func xpRequired(forLevel level: Int) -> Int {
        level * 50 + (level * level * 2)
    }

    // MARK: - Rewards

    func rewardForTask(_ task: MochiTask) -> TaskRewards {
        var xp = task.priority.xpReward
        let rice = task.priority.riceReward

        if task.wasCompletedBeforeDeadline {
            xp += 10
        }

        return TaskRewards(xp: xp, riceGrains: rice)
    }

    @discardableResult
    mutating func applyRewards(_ rewards: TaskRewards) -> Bool {
        let previousLevel = level
        currentXP += rewards.xp
        totalXP += rewards.xp
        riceGrains += rewards.riceGrains

        checkLevelUp()
        return level > previousLevel
    }

    // MARK: - Level Up

    mutating func checkLevelUp() {
        while currentXP >= xpRequiredForCurrentLevel {
            currentXP -= xpRequiredForCurrentLevel
            level += 1
            riceGrains += 10 // bonus level up
        }
    }

    // MARK: - Streak

    mutating func checkStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastActive = lastActiveDate else {
            streakDays = 1
            lastActiveDate = today
            return
        }

        let lastActiveDay = calendar.startOfDay(for: lastActive)

        if lastActiveDay == today {
            return
        }

        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        if daysSinceLastActive == 1 {
            streakDays += 1
        } else if daysSinceLastActive > 1 {
            streakDays = 1
        }

        lastActiveDate = today
    }

    var streakXPBonus: Int {
        5 * streakDays
    }
}
