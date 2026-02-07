import SwiftUI

struct MeetingProposalDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let proposal: MeetingProposal

    private var currentProposal: MeetingProposal {
        appState.meetingProposals.first(where: { $0.id == proposal.id }) ?? proposal
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Tasks list
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(currentProposal.suggestedTasks) { task in
                        suggestedTaskRow(task)
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            footer
        }
        .frame(width: 500, height: 480)
        .background(Color.white)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(MochiTheme.primary)

                Text(currentProposal.meetingTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight)
                    .lineLimit(2)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            if let date = currentProposal.meetingDate {
                Text(date, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
            }

            Text("\(currentProposal.suggestedTasks.count) tache\(currentProposal.suggestedTasks.count > 1 ? "s" : "") suggeree\(currentProposal.suggestedTasks.count > 1 ? "s" : "")")
                .font(.system(size: 12))
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
        }
        .padding(20)
    }

    // MARK: - Suggested Task Row

    private func suggestedTaskRow(_ task: SuggestedTask) -> some View {
        HStack(spacing: 12) {
            // Priority badge
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(task.isAccepted == false ? MochiTheme.textLight.opacity(0.35) : MochiTheme.textLight)
                    .strikethrough(task.isAccepted == false)

                if let desc = task.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.45))
                        .lineLimit(2)
                }

                Text(task.priority.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(priorityColor(task.priority))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(priorityColor(task.priority).opacity(0.1))
                    )
            }

            Spacer()

            // Action buttons
            if task.isAccepted == nil {
                HStack(spacing: 6) {
                    Button {
                        appState.acceptSuggestedTask(task.id, in: proposal.id)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.rejectSuggestedTask(task.id, in: proposal.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            } else if task.isAccepted == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green.opacity(0.5))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red.opacity(0.3))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(taskBackground(task))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            if currentProposal.status == .pending {
                Button {
                    appState.dismissProposal(proposal.id)
                    dismiss()
                } label: {
                    Text("Ignorer tout")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    appState.acceptAllTasks(in: proposal.id)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Tout accepter")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(MochiTheme.primary))
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                Text("Traitee")
                    .font(.system(size: 13))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                Spacer()
            }
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .normal: return .orange
        case .low: return .blue
        }
    }

    private func taskBackground(_ task: SuggestedTask) -> Color {
        if task.isAccepted == true {
            return Color.green.opacity(0.04)
        } else if task.isAccepted == false {
            return Color.gray.opacity(0.04)
        }
        return Color.white
    }
}
