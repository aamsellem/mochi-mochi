import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    private let tabs: [(String, String)] = [
        ("Général", "gear"),
        ("Personnalité", "face.smiling"),
        ("Notifications", "bell"),
        ("Notion", "link"),
        ("Raccourcis", "keyboard"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("Réglages")
                    .font(.title2.bold())
                    .foregroundStyle(MochiTheme.textLight)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    sidebarRow(tab.0, icon: tab.1, index: index)
                }

                Spacer()
            }
            .frame(width: 190)
            .background(MochiTheme.backgroundLight.opacity(0.5))

            // Content
            Group {
                switch appState.selectedSettingsTab {
                case 0: GeneralSettingsTab()
                case 1: PersonalitySettingsTab()
                case 2: NotificationSettingsTab()
                case 3: NotionSettingsTab()
                case 4: ShortcutSettingsTab()
                default: GeneralSettingsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL, style: .continuous)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func sidebarRow(_ title: String, icon: String, index: Int) -> some View {
        let isSelected = appState.selectedSettingsTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { appState.selectedSettingsTab = index }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? MochiTheme.primary : MochiTheme.textLight.opacity(0.3))
                    )
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? MochiTheme.textLight : MochiTheme.textLight.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? MochiTheme.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

// MARK: - Settings Card Container

private struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct SettingsRow<Content: View>: View {
    let label: String
    let icon: String?
    let iconColor: Color
    let showDivider: Bool
    let content: Content

    init(_ label: String, icon: String? = nil, iconColor: Color = MochiTheme.primary, showDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.showDivider = showDivider
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(iconColor))
                }
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(MochiTheme.textLight)
                    .frame(width: 130, alignment: .leading)
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showDivider {
                Divider()
                    .padding(.leading, icon != nil ? 50 : 14)
            }
        }
    }
}

// MARK: - Section Header

private func settingsSectionHeader(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
        .padding(.horizontal, 4)
        .padding(.top, 8)
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var appState: AppState

    @State private var mochiName: String = ""
    @State private var selectedColor: MochiColor = .pink
    @State private var userName: String = ""
    @State private var userOccupation: String = ""
    @State private var userGoal: String = ""

    private let goals = [
        "Mieux m'organiser", "Etre plus productif", "Apprendre des choses",
        "Reduire mon stress", "Atteindre mes objectifs", "Avoir un compagnon",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader("Profil")

                SettingsCard {
                    SettingsRow("Prenom", icon: "person.fill", iconColor: MochiTheme.secondary) {
                        settingsTextField("Ton prenom", text: $userName)
                    }

                    SettingsRow("Activite", icon: "briefcase.fill", iconColor: .orange) {
                        settingsTextField("Ton activite", text: $userOccupation, width: .infinity)
                    }

                    SettingsRow("Objectif", icon: "target", iconColor: .green, showDivider: false) {
                        settingsMenu(
                            value: userGoal,
                            placeholder: "Choisir",
                            options: goals
                        ) { userGoal = $0 }
                    }
                }

                settingsSectionHeader("Compagnon")

                SettingsCard {
                    SettingsRow("Nom", icon: "pencil", iconColor: MochiTheme.primary) {
                        settingsTextField("Nom du Mochi", text: $mochiName)
                    }

                    SettingsRow("Couleur", icon: "paintpalette.fill", iconColor: .orange, showDivider: false) {
                        EmptyView()
                    }

                    // Color picker grid
                    colorPickerGrid
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                }

                settingsSectionHeader("Donnees")

                SettingsCard {
                    SettingsRow("Emplacement", icon: "folder.fill", iconColor: .blue, showDivider: false) {
                        Text(MarkdownStorage.storedBaseDirectory.path
                            .replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                settingsSectionHeader("Application")

                SettingsCard {
                    VStack(spacing: 0) {
                        Button {
                            appState.isOnboardingComplete = false
                            appState.saveConfig()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.orange))
                                Text("Relancer l'onboarding")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MochiTheme.textLight)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.25))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            mochiName = appState.mochi.name
            selectedColor = appState.mochi.color
            userName = appState.userName
            userOccupation = appState.userOccupation
            userGoal = appState.userGoal
        }
        .onChange(of: mochiName) { _, newValue in
            appState.mochi.name = newValue
            appState.saveConfig()
        }
        .onChange(of: userName) { _, newValue in
            appState.userName = newValue
            appState.saveConfig()
        }
        .onChange(of: userOccupation) { _, newValue in
            appState.userOccupation = newValue
            appState.saveConfig()
        }
        .onChange(of: userGoal) { _, newValue in
            appState.userGoal = newValue
            appState.saveConfig()
        }
    }

    private func settingsTextField(_ placeholder: String, text: Binding<String>, width: CGFloat = 160) -> some View {
        MochiTextField(placeholder, text: text, fontSize: 13)
            .frame(height: 20)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(MochiTheme.backgroundLight.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
            )
            .frame(maxWidth: width)
    }

    private func settingsMenu(value: String, placeholder: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            Button("Aucun") { onSelect("") }
            Divider()
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option)
                        if value == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(size: 12))
                    .foregroundStyle(value.isEmpty ? MochiTheme.textLight.opacity(0.4) : MochiTheme.textLight)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.3))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(MochiTheme.backgroundLight.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var colorPickerGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(MochiColor.allCases, id: \.self) { color in
                    colorDot(color)
                }
            }
            if let nextColor = MochiColor.allCases.first(where: { !$0.isUnlocked(at: appState.gamification.level) }) {
                Text("Prochaine : \(nextColor.displayName) au niv. \(nextColor.requiredLevel)")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }
        }
    }

    private func colorDot(_ color: MochiColor) -> some View {
        let isSelected = selectedColor == color
        let isUnlocked = color.isUnlocked(at: appState.gamification.level)
        return Button {
            guard isUnlocked else { return }
            selectedColor = color
            appState.equipColor(color.displayName)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? colorPreview(color) : Color.gray.opacity(0.15))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(isSelected ? MochiTheme.primary : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? MochiTheme.primary.opacity(0.3) : .clear, radius: 3)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    }
                }
                Text(color.displayName)
                    .font(.system(size: 9))
                    .foregroundStyle(isUnlocked ? MochiTheme.textLight.opacity(0.5) : MochiTheme.textLight.opacity(0.25))
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private func colorPreview(_ color: MochiColor) -> Color {
        switch color {
        case .pink: return Color(hex: "FFB5C2")
        case .teal: return Color(hex: "8CD4C8")
        case .white: return Color(hex: "F2EDDE")
        case .matcha: return Color(hex: "BFE0B9")
        case .skyBlue: return Color(hex: "BFDDFF")
        case .golden: return Color(hex: "FFE699")
        case .grey: return Color(hex: "B8B8B8")
        case .black: return Color(hex: "2A2A2A")
        case .nightBlue: return Color(hex: "1E2659")
        case .violet: return Color(hex: "B373D9")
        case .pride: return Color(hex: "E65C5C")
        }
    }
}

// MARK: - Personality Settings

struct PersonalitySettingsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredPersonality: Personality? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader("Choisis la personnalité de ton Mochi")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 10) {
                    ForEach(Personality.allCases, id: \.self) { personality in
                        personalityCard(personality)
                    }
                }
            }
            .frame(maxWidth: 500)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: appState.currentPersonality) {
                appState.rescheduleAllNotifications()
            }
        }
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = appState.currentPersonality == personality

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.currentPersonality = personality
                appState.saveConfig()
            }
        } label: {
            HStack(spacing: 12) {
                Text(personality.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? MochiTheme.primary.opacity(0.15) : MochiTheme.backgroundLight)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(personality.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MochiTheme.textLight)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(MochiTheme.primary)
                        }
                    }
                    Text(personality.description)
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.45))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? MochiTheme.primary.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? MochiTheme.primary.opacity(0.35) : Color.gray.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isSelected ? MochiTheme.primary.opacity(0.08) : .black.opacity(0.02), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Settings

struct NotificationSettingsTab: View {
    @EnvironmentObject var appState: AppState

    private let frequencies: [(value: String, label: String, icon: String, description: String)] = [
        ("zen", "Zen", "leaf.fill", "Toutes les 2h"),
        ("normal", "Normal", "bell.fill", "Toutes les heures"),
        ("intense", "Intense", "bolt.fill", "Toutes les 15 min"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if appState.notificationsBlocked {
                    notificationsBlockedBanner
                }

                settingsSectionHeader("Fréquence des relances")

                HStack(spacing: 10) {
                    ForEach(frequencies, id: \.value) { freq in
                        frequencyCard(freq.value, label: freq.label, icon: freq.icon, description: freq.description)
                    }
                }

                settingsSectionHeader("Briefing matinal")

                SettingsCard {
                    SettingsRow("Briefing matinal", icon: "sunrise.fill", iconColor: .orange) {
                        Toggle("", isOn: $appState.morningBriefingEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .tint(MochiTheme.primary)
                    }

                    SettingsRow("Heure d'envoi", icon: "clock.fill", iconColor: .blue, showDivider: false) {
                        Menu {
                            ForEach(6..<13, id: \.self) { hour in
                                Button {
                                    appState.morningBriefingHour = hour
                                } label: {
                                    HStack {
                                        Text("\(hour)h00")
                                        if appState.morningBriefingHour == hour {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text("\(appState.morningBriefingHour)h00")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MochiTheme.textLight)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(MochiTheme.backgroundLight.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                                    )
                            )
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                    .opacity(appState.morningBriefingEnabled ? 1 : 0.4)
                    .disabled(!appState.morningBriefingEnabled)
                }

                settingsSectionHeader("Streak")

                SettingsCard {
                    SettingsRow("Proteger les week-ends", icon: "calendar", iconColor: .green, showDivider: false) {
                        Toggle("", isOn: $appState.weekendsProtected)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .tint(MochiTheme.primary)
                    }
                }

                Text("Les week-ends ne casseront pas votre streak si active.")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.35))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: appState.notificationFrequency) {
                appState.rescheduleAllNotifications()
                appState.saveConfig()
            }
            .onChange(of: appState.morningBriefingEnabled) {
                appState.rescheduleAllNotifications()
                appState.saveConfig()
            }
            .onChange(of: appState.morningBriefingHour) {
                appState.rescheduleAllNotifications()
                appState.saveConfig()
            }
            .onChange(of: appState.weekendsProtected) {
                appState.saveConfig()
            }
        }
        .task {
            await appState.refreshNotificationStatus()
        }
    }

    private var notificationsBlockedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications desactivees")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MochiTheme.textLight)
                Text("Activez les notifications pour Mochi Mochi dans les Reglages Systeme.")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.6))
            }

            Spacer()

            Button {
                // Open System Settings > Notifications for this app
                if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text("Ouvrir")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MochiTheme.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func frequencyCard(_ value: String, label: String, icon: String, description: String) -> some View {
        let isSelected = appState.notificationFrequency == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.notificationFrequency = value
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? MochiTheme.primary : MochiTheme.textLight.opacity(0.35))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? MochiTheme.textLight : MochiTheme.textLight.opacity(0.6))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? MochiTheme.primary.opacity(0.7) : MochiTheme.textLight.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? MochiTheme.primary.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? MochiTheme.primary.opacity(0.4) : Color.gray.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isSelected ? MochiTheme.primary.opacity(0.08) : .clear, radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notion Settings

struct NotionSettingsTab: View {
    @State private var notionToken = ""
    @State private var isConnected = false
    @State private var databaseId = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader("Connexion")

                SettingsCard {
                    SettingsRow("Statut", icon: "wifi", iconColor: isConnected ? .green : .gray, showDivider: isConnected) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isConnected ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(isConnected ? "Connecté" : "Non connecté")
                                .font(.system(size: 12))
                                .foregroundStyle(isConnected ? .green : MochiTheme.textLight.opacity(0.5))
                        }
                    }

                    if isConnected {
                        SettingsRow("Base de données", icon: "tablecells", iconColor: .blue, showDivider: true) {
                            TextField("ID", text: $databaseId)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(MochiTheme.textLight)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 200)
                        }

                        VStack(spacing: 0) {
                            Button {
                                disconnectNotion()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white)
                                        .frame(width: 22, height: 22)
                                        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.red.opacity(0.8)))
                                    Text("Déconnecter")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.red.opacity(0.8))
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !isConnected {
                    settingsSectionHeader("Authentification")

                    SettingsCard {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Token d'intégration Notion")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                                SecureField("ntn_...", text: $notionToken)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(MochiTheme.textLight)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(MochiTheme.backgroundLight)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                                    )
                            }
                            .padding(14)

                            Divider()

                            Button {
                                connectNotion()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Connecter")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(notionToken.isEmpty ? MochiTheme.textLight.opacity(0.3) : MochiTheme.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            .disabled(notionToken.isEmpty)
                        }
                    }
                }

                settingsSectionHeader("Synchronisation")

                Text("La synchronisation bidirectionnelle avec Notion permet de garder vos tâches à jour sur les deux plateformes.")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.35))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if let token = KeychainHelper.load(key: "notion_token") {
                notionToken = token
                isConnected = true
            }
        }
    }

    private func connectNotion() {
        try? KeychainHelper.save(key: "notion_token", value: notionToken)
        isConnected = true
    }

    private func disconnectNotion() {
        try? KeychainHelper.delete(key: "notion_token")
        notionToken = ""
        isConnected = false
    }
}

// MARK: - Shortcut Settings

struct ShortcutSettingsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader("Raccourcis globaux")

                SettingsCard {
                    shortcutRow("Ouvrir/fermer le chat", icon: "message.fill", iconColor: MochiTheme.primary, shortcut: "⌘⇧M")
                    shortcutRow("Mini-panel menubar", icon: "menubar.rectangle", iconColor: .purple, shortcut: "⌘⇧N")
                    shortcutRow("Ajout rapide de tâche", icon: "plus.circle.fill", iconColor: .green, shortcut: "⌘⇧A", showDivider: false)
                }

                Text("La personnalisation des raccourcis sera disponible dans une future version.")
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.35))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func shortcutRow(_ label: String, icon: String, iconColor: Color, shortcut: String, showDivider: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(iconColor))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(MochiTheme.textLight)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(shortcutKeys(shortcut), id: \.self) { key in
                        Text(key)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(MochiTheme.backgroundLight)
                                    .shadow(color: .black.opacity(0.06), radius: 0.5, y: 0.5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showDivider {
                Divider().padding(.leading, 50)
            }
        }
    }

    private func shortcutKeys(_ shortcut: String) -> [String] {
        shortcut.map { String($0) }
    }
}
