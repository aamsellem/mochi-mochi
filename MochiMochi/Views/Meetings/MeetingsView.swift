import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProposal: MeetingProposal?
    @State private var searchText: String = ""

    private var filteredProposals: [MeetingProposal] {
        let sorted = appState.meetingProposals.sorted { a, b in
            let dateA = a.meetingDate ?? .distantPast
            let dateB = b.meetingDate ?? .distantPast
            return dateA > dateB
        }
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter { proposal in
            proposal.meetingTitle.lowercased().contains(query)
            || proposal.suggestedTasks.contains { $0.title.lowercased().contains(query) }
        }
    }

    private var pendingProposals: [MeetingProposal] {
        filteredProposals.filter { $0.status == .pending }
    }

    private var reviewedProposals: [MeetingProposal] {
        filteredProposals.filter { $0.status == .reviewed }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !appState.meetingWatchEnabled {
                disabledState
            } else if appState.meetingProposals.isEmpty {
                emptyState
            } else {
                proposalsList
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .sheet(item: $selectedProposal) { proposal in
            MeetingProposalDetailView(proposal: proposal)
                .environmentObject(appState)
        }
    }

    // MARK: - Disabled State

    private var disabledState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(MochiTheme.textLight.opacity(0.2))

            Text("Veille de reunions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)

            Text("Activez la veille de reunions dans\nReglages > Notion pour detecter\nautomatiquement vos reunions.")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .multilineTextAlignment(.center)

            Button {
                appState.selectedSettingsTab = 3
                appState.selectedTab = .settings
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("Ouvrir les reglages")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(MochiTheme.primary))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(MochiTheme.textLight.opacity(0.2))

            Text("Aucune nouvelle reunion")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)

            Text("La veille est active. Les nouvelles reunions\ndetectees dans Notion apparaitront ici.")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .multilineTextAlignment(.center)

            if appState.isCheckingMeetings {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.top, 4)
            } else {
                Button {
                    Task { await appState.checkForNewMeetings() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Verifier maintenant")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(MochiTheme.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(MochiTheme.primary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Proposals List

    private var proposalsList: some View {
        VStack(spacing: 0) {
            // Header + Search
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Reunions")
                        .font(.title2.bold())
                        .foregroundStyle(MochiTheme.textLight)

                    if appState.pendingProposalsCount > 0 {
                        Text("\(appState.pendingProposalsCount) en attente")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(MochiTheme.primary))
                    }

                    Spacer()

                    if appState.isCheckingMeetings {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button {
                            Task { await appState.checkForNewMeetings() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.35))

                    TextField("Rechercher une reunion ou tache...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(MochiTheme.textLight)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MochiTheme.backgroundLight.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .padding(24)
            .padding(.bottom, 0)

            // List
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if filteredProposals.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 24))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.2))
                                Text("Aucun resultat pour \"\(searchText)\"")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                    } else {
                        // Pending proposals
                        if !pendingProposals.isEmpty {
                            sectionHeader("En attente", count: pendingProposals.count, color: MochiTheme.primary)

                            ForEach(pendingProposals) { proposal in
                                proposalCard(proposal, isPending: true)
                            }
                        }

                        // Reviewed proposals
                        if !reviewedProposals.isEmpty {
                            sectionHeader("Traitees", count: reviewedProposals.count, color: .green)
                                .padding(.top, pendingProposals.isEmpty ? 0 : 12)

                            ForEach(reviewedProposals) { proposal in
                                proposalCard(proposal, isPending: false)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                .tracking(0.5)

            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(color.opacity(0.1))
                )

            VStack { Divider() }
        }
    }

    // MARK: - Proposal Card

    private func proposalCard(_ proposal: MeetingProposal, isPending: Bool) -> some View {
        Button {
            selectedProposal = proposal
        } label: {
            HStack(spacing: 14) {
                // Date column
                VStack(spacing: 2) {
                    if let date = proposal.meetingDate {
                        Text(dayString(date))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(isPending ? MochiTheme.primary : MochiTheme.textLight.opacity(0.35))
                        Text(monthString(date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isPending ? MochiTheme.primary.opacity(0.7) : MochiTheme.textLight.opacity(0.3))
                            .textCase(.uppercase)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundStyle(isPending ? MochiTheme.primary : MochiTheme.textLight.opacity(0.3))
                    }
                }
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isPending ? MochiTheme.primary.opacity(0.08) : Color.gray.opacity(0.05))
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(proposal.meetingTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isPending ? MochiTheme.textLight : MochiTheme.textLight.opacity(0.5))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let date = proposal.meetingDate {
                            Text(relativeDateString(date))
                                .font(.system(size: 11))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "checklist")
                                .font(.system(size: 9))
                            Text("\(proposal.suggestedTasks.count) tache\(proposal.suggestedTasks.count > 1 ? "s" : "")")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    }
                }

                Spacer()

                if isPending {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MochiTheme.primary.opacity(0.5))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.green.opacity(0.5))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isPending ? Color.white : Color.gray.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isPending ? MochiTheme.primary.opacity(0.15) : Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isPending ? MochiTheme.primary.opacity(0.05) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Helpers

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func relativeDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0

        if days == 0 { return "Aujourd'hui" }
        if days == 1 { return "Hier" }
        if days < 7 { return "Il y a \(days) jours" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
