import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProposal: MeetingProposal?
    @State private var searchText: String = ""
    @State private var showIgnored: Bool = false
    @State private var meetingToIgnore: MeetingProposal?

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
            || proposal.attendees.contains { $0.lowercased().contains(query) }
            || proposal.suggestedTasks.contains { $0.title.lowercased().contains(query) }
        }
    }

    // MARK: - Filtered lists

    private var preparing: [MeetingProposal] {
        filteredProposals.filter { $0.status == .preparing }
    }
    private var outlookPrepared: [MeetingProposal] {
        filteredProposals.filter { $0.source == .outlook && $0.status == .prepared }
    }
    private var notionToReview: [MeetingProposal] {
        filteredProposals.filter { $0.source == .notion && $0.status == .prepared }
    }
    private var reviewed: [MeetingProposal] {
        filteredProposals.filter { $0.status == .reviewed }
    }
    private var ignored: [MeetingProposal] {
        filteredProposals.filter { $0.status == .ignored }
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
        .confirmationDialog(
            "Ignorer cette reunion ?",
            isPresented: Binding(
                get: { meetingToIgnore != nil },
                set: { if !$0 { meetingToIgnore = nil } }
            ),
            presenting: meetingToIgnore
        ) { proposal in
            Button("Ignorer cette reunion uniquement") {
                appState.ignoreMeeting(proposal.id)
                meetingToIgnore = nil
            }
            Button("Ignorer et exclure les futures similaires") {
                appState.ignoreMeetingAndExclude(proposal.id)
                meetingToIgnore = nil
            }
            Button("Annuler", role: .cancel) {
                meetingToIgnore = nil
            }
        } message: { proposal in
            Text("\"\(proposal.meetingTitle)\"")
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
            Text("Activez la veille dans Reglages > Reunions\npour detecter vos reunions automatiquement.")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .multilineTextAlignment(.center)
            Button {
                appState.selectedSettingsTab = 3
                appState.selectedTab = .settings
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape").font(.system(size: 12))
                    Text("Ouvrir les reglages").font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 10)
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
            Text("Aucune reunion detectee")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)
            Text("La veille est active. Les reunions\ndetectees via Outlook et Notion\napparaitront ici.")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .multilineTextAlignment(.center)
            if appState.isCheckingMeetings {
                ProgressView().scaleEffect(0.8).padding(.top, 4)
            } else {
                Button {
                    Task { await appState.checkForNewMeetings() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 12))
                        Text("Verifier maintenant").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(MochiTheme.primary)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Capsule().stroke(MochiTheme.primary, lineWidth: 1))
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
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Reunions")
                        .font(.title2.bold())
                        .foregroundStyle(MochiTheme.textLight)

                    if appState.pendingProposalsCount > 0 {
                        Text("\(appState.pendingProposalsCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Circle().fill(MochiTheme.primary))
                    }

                    Spacer()

                    if appState.isCheckingMeetings {
                        ProgressView().scaleEffect(0.7)
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
                    TextField("Rechercher...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(MochiTheme.textLight)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(MochiTheme.backgroundLight.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .padding(24).padding(.bottom, 0)

            // Content — Kanban board
            if filteredProposals.isEmpty {
                ScrollView {
                    noResults
                        .padding(.horizontal, 24)
                        .padding(.top, 8).padding(.bottom, 24)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        // Column 1: En preparation
                        if !preparing.isEmpty {
                            kanbanColumn(
                                title: "En preparation",
                                icon: "arrow.triangle.2.circlepath",
                                count: preparing.count,
                                color: .orange
                            ) {
                                ForEach(preparing) { preparingCard($0) }
                            }
                        }

                        // Column 2: Preparees (Outlook)
                        if !outlookPrepared.isEmpty {
                            kanbanColumn(
                                title: "Preparees",
                                icon: "checkmark.seal",
                                count: outlookPrepared.count,
                                color: MochiTheme.secondary
                            ) {
                                ForEach(outlookPrepared) { outlookPreparedCard($0) }
                            }
                        }

                        // Column 3: Notes a traiter (Notion)
                        if !notionToReview.isEmpty {
                            kanbanColumn(
                                title: "Notes a traiter",
                                icon: "doc.text.magnifyingglass",
                                count: notionToReview.count,
                                color: MochiTheme.primary
                            ) {
                                ForEach(notionToReview) { notionCard($0) }
                            }
                        }

                        // Column 4: Traitees
                        if !reviewed.isEmpty {
                            kanbanColumn(
                                title: "Traitees",
                                icon: "checkmark.circle",
                                count: reviewed.count,
                                color: .green
                            ) {
                                ForEach(reviewed) { reviewedCard($0) }
                            }
                        }

                        // Column 5: Ignorees (collapsed by default)
                        if !ignored.isEmpty {
                            kanbanColumn(
                                title: "Ignorees",
                                icon: "eye.slash",
                                count: ignored.count,
                                color: .gray,
                                collapsed: !showIgnored,
                                onToggle: { showIgnored.toggle() }
                            ) {
                                ForEach(ignored) { ignoredCard($0) }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8).padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Kanban Column

    private func kanbanColumn<Content: View>(
        title: String,
        icon: String,
        count: Int,
        color: Color,
        collapsed: Bool = false,
        onToggle: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            Button {
                if let onToggle { withAnimation(.easeInOut(duration: 0.2)) { onToggle() } }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(color)

                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                        .tracking(0.5)

                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(color.opacity(0.1)))

                    if onToggle != nil {
                        Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            if !collapsed {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        content()
                    }
                }
            }
        }
        .frame(width: 280)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - No Results

    private var noResults: some View {
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
    }

    // MARK: - Preparing Card (spinner)

    private func preparingCard(_ proposal: MeetingProposal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                dateColumn(proposal, color: .orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text(proposal.meetingTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(MochiTheme.textLight)
                        .lineLimit(2)
                    if let date = proposal.meetingDate {
                        Text(relativeDateString(date))
                            .font(.system(size: 11))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    }
                }
            }
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.6)
                Text("Preparation en cours...")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.orange.opacity(0.05), radius: 3, y: 1)
    }

    // MARK: - Outlook Prepared Card

    private func outlookPreparedCard(_ proposal: MeetingProposal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { selectedProposal = proposal } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        dateColumn(proposal, color: MochiTheme.secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(proposal.meetingTitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MochiTheme.textLight)
                                .lineLimit(2)
                            if let date = proposal.meetingDate {
                                HStack(spacing: 4) {
                                    Text(relativeDateString(date))
                                    if let endDate = proposal.meetingEndDate {
                                        Text("•")
                                        Text(date, style: .time)
                                        Text("-")
                                        Text(endDate, style: .time)
                                    }
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                            }
                        }
                    }

                    if let summary = proposal.prepSummary {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        if proposal.preReadNotionUrl != nil {
                            notionBadge("Preparation", icon: "doc.text.fill")
                        }
                        if proposal.agendaNotionUrl != nil {
                            notionBadge("Reunion", icon: "list.bullet.rectangle.fill")
                        }
                        if !proposal.suggestedTasks.isEmpty {
                            taskCountBadge(proposal.suggestedTasks.count)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Action buttons
            HStack(spacing: 6) {
                Button {
                    meetingToIgnore = proposal
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash").font(.system(size: 10))
                        Text("Ignorer").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if proposal.preReadNotionUrl == nil && proposal.agendaNotionUrl == nil {
                    Button {
                        Task { await appState.prepareMeeting(proposal) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise").font(.system(size: 10))
                            Text("Re-preparer").font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(MochiTheme.primary))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MochiTheme.secondary.opacity(0.4))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(MochiTheme.secondary.opacity(0.15), lineWidth: 1))
        .shadow(color: MochiTheme.secondary.opacity(0.05), radius: 3, y: 1)
    }

    // MARK: - Notion Card

    private func notionCard(_ proposal: MeetingProposal) -> some View {
        Button { selectedProposal = proposal } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    dateColumn(proposal, color: MochiTheme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(proposal.meetingTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MochiTheme.textLight)
                            .lineLimit(2)
                    }
                }

                if !proposal.suggestedTasks.isEmpty {
                    taskCountBadge(proposal.suggestedTasks.count, label: "tache\(proposal.suggestedTasks.count > 1 ? "s" : "") suggeree\(proposal.suggestedTasks.count > 1 ? "s" : "")")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(MochiTheme.primary.opacity(0.15), lineWidth: 1))
            .shadow(color: MochiTheme.primary.opacity(0.05), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reviewed Card

    private func reviewedCard(_ proposal: MeetingProposal) -> some View {
        Button { selectedProposal = proposal } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    dateColumn(proposal, color: MochiTheme.textLight.opacity(0.3))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(proposal.meetingTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                            .lineLimit(2)

                        Text(proposal.source == .outlook ? "Outlook" : "Notion")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(MochiTheme.textLight.opacity(0.06)))
                    }
                }

                HStack(spacing: 8) {
                    let accepted = proposal.suggestedTasks.filter { $0.isAccepted == true }.count
                    let rejected = proposal.suggestedTasks.filter { $0.isAccepted == false }.count

                    if accepted > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark").font(.system(size: 9))
                            Text("\(accepted) acceptee\(accepted > 1 ? "s" : "")")
                        }
                        .font(.system(size: 11)).foregroundStyle(.green.opacity(0.6))
                    }
                    if rejected > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark").font(.system(size: 9))
                            Text("\(rejected) rejetee\(rejected > 1 ? "s" : "")")
                        }
                        .font(.system(size: 11)).foregroundStyle(.red.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green.opacity(0.5))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ignored Card

    private func ignoredCard(_ proposal: MeetingProposal) -> some View {
        HStack(spacing: 10) {
            dateColumn(proposal, color: .gray)
            VStack(alignment: .leading, spacing: 3) {
                Text(proposal.meetingTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    .lineLimit(2)
                if let date = proposal.meetingDate {
                    Text(relativeDateString(date))
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.25))
                }
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Reusable Badges

    private func notionBadge(_ label: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(label)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(MochiTheme.secondary)
    }

    private func taskCountBadge(_ count: Int, label: String? = nil) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "checklist").font(.system(size: 9))
            Text(label ?? "\(count) tache\(count > 1 ? "s" : "")")
        }
        .font(.system(size: 10))
        .foregroundStyle(MochiTheme.textLight.opacity(0.4))
    }

    // MARK: - Date Column

    private func dateColumn(_ proposal: MeetingProposal, color: Color) -> some View {
        VStack(spacing: 2) {
            if let date = proposal.meetingDate {
                Text(dayString(date))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(monthString(date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color.opacity(0.7))
                    .textCase(.uppercase)
            } else {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
        }
        .frame(width: 40, height: 40)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.08)))
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
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0

        if days == 0 { return "Aujourd'hui" }
        if days == 1 { return "Demain" }
        if days > 1 && days < 7 { return "Dans \(days) jours" }
        if days == -1 { return "Hier" }
        if days < -1 { return "Il y a \(abs(days)) jours" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
