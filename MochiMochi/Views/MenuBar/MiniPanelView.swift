import SwiftUI

struct MiniPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var quickTaskText = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            quickAddSection
            Divider()
            taskListSection
            if let nextDeadline = nextDeadlineTask {
                Divider()
                deadlineSection(nextDeadline)
            }
            Divider()
            openAppButton
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("🍡")
                    .font(.title2)
                Text(appState.mochi.name)
                    .font(.headline)
                Text("(Niv.\(appState.gamification.level))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(appState.gamification.streakDays)j", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            ProgressView(value: appState.gamification.xpProgress)
                .tint(.purple)

            HStack {
                Text("\(appState.gamification.currentXP)/\(appState.gamification.xpRequiredForCurrentLevel) XP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(appState.gamification.riceGrains)", systemImage: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        HStack(spacing: 8) {
            TextField("Ajouter une tache...", text: $quickTaskText)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .onSubmit {
                    addQuickTask()
                }

            Button {
                addQuickTask()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .disabled(quickTaskText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
    }

    // MARK: - Task List

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Taches du jour")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completedTodayCount)/\(todayTasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if todayTasks.isEmpty {
                Text("Aucune tache pour aujourd'hui")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(todayTasks) { task in
                    miniTaskRow(task)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func miniTaskRow(_ task: MochiTask) -> some View {
        HStack(spacing: 8) {
            Button {
                if !task.isCompleted {
                    appState.completeTask(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted)

            Text(task.title)
                .font(.callout)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Deadline

    private func deadlineSection(_ task: MochiTask) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text("Prochain:")
                .font(.caption.bold())
            Text(task.title)
                .font(.caption)
                .lineLimit(1)
            if let deadline = task.deadline {
                Spacer()
                Text(deadlineText(deadline))
                    .font(.caption)
                    .foregroundStyle(task.isOverdue ? .red : .orange)
            }
        }
        .padding(12)
    }

    // MARK: - Open App Button

    private var openAppButton: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        } label: {
            Text("Ouvrir Mochi Mochi")
                .font(.callout.bold())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(12)
    }

    // MARK: - Helpers

    private var todayTasks: [MochiTask] {
        appState.tasks.filter { !$0.isCompleted || isCompletedToday($0) }
    }

    private var completedTodayCount: Int {
        todayTasks.filter { $0.isCompleted }.count
    }

    private var nextDeadlineTask: MochiTask? {
        appState.tasks
            .filter { !$0.isCompleted && $0.deadline != nil }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
            .first
    }

    private func isCompletedToday(_ task: MochiTask) -> Bool {
        guard let completedAt = task.completedAt else { return false }
        return Calendar.current.isDateInToday(completedAt)
    }

    private func deadlineText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
