import SwiftUI

struct TaskRowView: View {
    let task: MochiTask
    @EnvironmentObject var appState: AppState
    @State private var showReward = false
    @State private var rewardText = ""

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button {
                completeTask()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(task.isCompleted)

            // Title
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            Spacer()

            // Priority badge
            priorityBadge

            // Deadline
            if let deadline = task.deadline {
                deadlineLabel(deadline)
            }

            // Reward animation
            if showReward {
                Text(rewardText)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(task.isOverdue ? Color.red.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var priorityBadge: some View {
        Text(task.priority.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.15))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .red
        }
    }

    private func deadlineLabel(_ date: Date) -> some View {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .abbreviated
        let text = formatter.localizedString(for: date, relativeTo: Date())

        return Text(text)
            .font(.caption)
            .foregroundStyle(task.isOverdue ? .red : .secondary)
    }

    private func completeTask() {
        let rewards = appState.gamification.rewardForTask(task)
        rewardText = "+\(rewards.xp) XP  +\(rewards.riceGrains) 🍙"

        withAnimation(.spring(response: 0.3)) {
            showReward = true
            appState.completeTask(task)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showReward = false
            }
        }
    }
}
