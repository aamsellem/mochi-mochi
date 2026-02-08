import SwiftUI

struct MeetingProposalDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showIgnoreDialog: Bool = false

    let proposal: MeetingProposal

    private var currentProposal: MeetingProposal {
        appState.meetingProposals.first(where: { $0.id == proposal.id }) ?? proposal
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Preparation summary
                    if let summary = currentProposal.prepSummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Resume de la preparation")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                                .textCase(.uppercase)

                            Text(summary)
                                .font(.system(size: 13))
                                .foregroundStyle(MochiTheme.textLight)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(MochiTheme.backgroundLight.opacity(0.5))
                                )
                        }
                    }

                    // Notion links
                    if currentProposal.preReadNotionUrl != nil || currentProposal.agendaNotionUrl != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Documents Notion")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                                .textCase(.uppercase)

                            HStack(spacing: 10) {
                                if let preReadUrl = currentProposal.preReadNotionUrl,
                                   let url = URL(string: preReadUrl) {
                                    Link(destination: url) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 12))
                                            Text("Preparation")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(MochiTheme.secondary)
                                        )
                                    }
                                }

                                if let agendaUrl = currentProposal.agendaNotionUrl,
                                   let url = URL(string: agendaUrl) {
                                    Link(destination: url) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "list.bullet.rectangle.fill")
                                                .font(.system(size: 12))
                                            Text("Reunion")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(MochiTheme.secondary.opacity(0.8))
                                        )
                                    }
                                }
                            }
                        }
                    } else if currentProposal.source == .outlook && currentProposal.status == .prepared {
                        // No Notion links — preparation ran but couldn't create docs
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Documents Notion")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                                .textCase(.uppercase)

                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.orange)
                                Text("Les documents Preparation et Reunion n'ont pas pu etre crees dans Notion (MCP non connecte).")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.orange.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                                    )
                            )

                            Button {
                                Task { await appState.prepareMeeting(currentProposal) }
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Re-preparer")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(MochiTheme.primary))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Suggested tasks
                    if !currentProposal.suggestedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Taches suggerees")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                                .textCase(.uppercase)

                            ForEach(currentProposal.suggestedTasks) { task in
                                suggestedTaskRow(task)
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            footer
        }
        .frame(width: 520, height: 530)
        .background(Color.white)
        .confirmationDialog(
            "Ignorer cette reunion ?",
            isPresented: $showIgnoreDialog
        ) {
            Button("Ignorer cette reunion uniquement") {
                appState.ignoreMeeting(proposal.id)
                dismiss()
            }
            Button("Ignorer et exclure les futures similaires") {
                appState.ignoreMeetingAndExclude(proposal.id)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("\"\(currentProposal.meetingTitle)\"")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                HStack(spacing: 4) {
                    Text(date, style: .date)
                    if let endDate = currentProposal.meetingEndDate {
                        Text("•")
                        Text(date, style: .time)
                        Text("-")
                        Text(endDate, style: .time)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
            }

            HStack(spacing: 12) {
                if !currentProposal.attendees.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                        Text(currentProposal.attendees.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.45))
                }

                if let location = currentProposal.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(location)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.45))
                }
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
            if currentProposal.status == .prepared || currentProposal.status == .discovered {
                Button {
                    showIgnoreDialog = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11))
                        Text("Ignorer")
                            .font(.system(size: 13, weight: .medium))
                    }
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
            } else if currentProposal.status == .ignored {
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 12))
                    Text("Ignoree")
                        .font(.system(size: 13))
                }
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                Spacer()
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
