import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mochiSection
                tasksSection
                statisticsSection
                objectivesSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Mochi Section

    private var mochiSection: some View {
        GroupBox {
            HStack(spacing: 24) {
                MochiAvatarView(
                    emotion: appState.mochi.emotion,
                    color: appState.mochi.color,
                    equippedItems: appState.mochi.equippedItems,
                    size: 90
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.mochi.name)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        Text("Niv. \(appState.gamification.level)")
                            .font(.headline)
                        xpProgressBar
                    }

                    HStack(spacing: 16) {
                        Label("\(appState.gamification.riceGrains) 🍙", systemImage: "leaf.fill")
                            .foregroundStyle(.orange)
                        Label("\(appState.gamification.streakDays)j", systemImage: "flame.fill")
                            .foregroundStyle(.red)
                        Text(emotionLabel)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(emotionColor.opacity(0.15))
                            .foregroundStyle(emotionColor)
                            .clipShape(Capsule())
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .padding(8)
        } label: {
            Label("Mon Mochi", systemImage: "heart.fill")
        }
    }

    private var xpProgressBar: some View {
        let progress = appState.gamification.xpProgress
        return HStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(width: 120, height: 8)

            Text("\(appState.gamification.currentXP)/\(appState.gamification.xpRequiredForCurrentLevel) XP")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emotionLabel: String {
        switch appState.mochi.emotion {
        case .idle: return "Tranquille"
        case .happy: return "Content"
        case .excited: return "Excite"
        case .focused: return "Concentre"
        case .sleeping: return "Endormi"
        case .worried: return "Inquiet"
        case .sad: return "Triste"
        case .proud: return "Fier"
        case .thinking: return "Reflechit"
        }
    }

    private var emotionColor: Color {
        switch appState.mochi.emotion {
        case .idle: return .secondary
        case .happy: return .green
        case .excited: return .yellow
        case .focused: return .blue
        case .sleeping: return .indigo
        case .worried: return .orange
        case .sad: return .purple
        case .proud: return .yellow
        case .thinking: return .cyan
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if !overdueTasks.isEmpty {
                    taskSubSection(title: "En retard", tasks: overdueTasks, color: .red)
                }
                if !pendingTasks.isEmpty {
                    taskSubSection(title: "A faire", tasks: pendingTasks, color: .blue)
                }
                if !completedTodayTasks.isEmpty {
                    taskSubSection(title: "Completees aujourd'hui", tasks: completedTodayTasks, color: .green)
                }
                if overdueTasks.isEmpty && pendingTasks.isEmpty && completedTodayTasks.isEmpty {
                    Text("Aucune tache pour le moment.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(4)
        } label: {
            Label("Taches", systemImage: "checklist")
        }
    }

    private func taskSubSection(title: String, tasks: [MochiTask], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                Text("(\(tasks.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(tasks) { task in
                TaskRowView(task: task)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        GroupBox {
            HStack(spacing: 24) {
                statCard(title: "Completees", value: "\(completedTasksCount)", icon: "checkmark.circle.fill", color: .green)
                statCard(title: "En cours", value: "\(pendingTasks.count)", icon: "circle.dashed", color: .blue)
                statCard(title: "En retard", value: "\(overdueTasks.count)", icon: "exclamationmark.triangle.fill", color: .red)
                statCard(title: "Streak", value: "\(appState.gamification.streakDays)j", icon: "flame.fill", color: .orange)
            }
            .padding(8)
        } label: {
            Label("Statistiques", systemImage: "chart.bar.fill")
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.06))
        )
    }

    // MARK: - Objectives Section

    private var objectivesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("Les objectifs long terme seront affiches ici.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding(4)
        } label: {
            Label("Objectifs", systemImage: "target")
        }
    }

    // MARK: - Computed Properties

    private var pendingTasks: [MochiTask] {
        appState.tasks.filter { !$0.isCompleted && !$0.isOverdue }
    }

    private var overdueTasks: [MochiTask] {
        appState.tasks.filter { $0.isOverdue }
    }

    private var completedTodayTasks: [MochiTask] {
        appState.tasks.filter {
            guard let completedAt = $0.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }
    }

    private var completedTasksCount: Int {
        appState.tasks.filter { $0.isCompleted }.count
    }
}
