import SwiftUI

struct SettingsView: View {
    @State private var selectedSettingsTab = 0

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader
            Divider().opacity(0.3)
            settingsTabs
            Divider().opacity(0.3)

            Group {
                switch selectedSettingsTab {
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

    private var settingsHeader: some View {
        HStack {
            Text("Réglages")
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var settingsTabs: some View {
        HStack(spacing: 4) {
            settingsTabButton("Général", icon: "gear", index: 0)
            settingsTabButton("Personnalité", icon: "face.smiling", index: 1)
            settingsTabButton("Notifications", icon: "bell", index: 2)
            settingsTabButton("Notion", icon: "link", index: 3)
            settingsTabButton("Raccourcis", icon: "keyboard", index: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func settingsTabButton(_ title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedSettingsTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedSettingsTab = index }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? MochiTheme.primary.opacity(0.15) : Color.clear)
            )
            .foregroundStyle(isSelected ? MochiTheme.primary : MochiTheme.textLight.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var appState: AppState

    @State private var mochiName: String = ""
    @State private var selectedColor: MochiColor = .pink

    private var unlockedColors: [MochiColor] {
        MochiColor.allCases.filter { $0.isUnlocked(at: appState.gamification.level) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsSection("Mochi") {
                    settingsField("Nom du Mochi") {
                        TextField("Nom", text: $mochiName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundStyle(MochiTheme.textLight)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(MochiTheme.backgroundLight)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                            )
                    }

                    settingsField("Couleur") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                ForEach(MochiColor.allCases, id: \.self) { color in
                                    colorDot(color)
                                }
                            }
                            if let nextColor = MochiColor.allCases.first(where: { !$0.isUnlocked(at: appState.gamification.level) }) {
                                Text("Prochaine couleur : \(nextColor.displayName) au niveau \(nextColor.requiredLevel)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                            }
                        }
                    }
                }

                settingsSection("Stockage") {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(MochiTheme.primary.opacity(0.6))
                        Text(MarkdownStorage.storedBaseDirectory.path
                            .replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(MochiTheme.textLight)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                settingsSection("Application") {
                    Button {
                        appState.isOnboardingComplete = false
                        appState.saveConfig()
                    } label: {
                        Text("Relancer l'onboarding")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .onAppear {
            mochiName = appState.mochi.name
            selectedColor = appState.mochi.color
        }
        .onChange(of: mochiName) { _, newValue in
            appState.mochi.name = newValue
            appState.saveConfig()
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
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? colorPreview(color) : Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(isSelected ? MochiTheme.primary : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? MochiTheme.primary.opacity(0.3) : .clear, radius: 4)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.4))
                    }
                }
                VStack(spacing: 1) {
                    Text(color.displayName)
                        .font(.system(size: 10))
                        .foregroundStyle(isUnlocked ? MochiTheme.textLight.opacity(0.6) : MochiTheme.textLight.opacity(0.3))
                    if !isUnlocked {
                        Text("Niv. \(color.requiredLevel)")
                            .font(.system(size: 8))
                            .foregroundStyle(MochiTheme.textLight.opacity(0.3))
                    }
                }
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

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                ForEach(Personality.allCases, id: \.self) { personality in
                    personalityCard(personality)
                }
            }
            .padding(20)
        }
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = appState.currentPersonality == personality

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(personality.emoji)
                    .font(.title2)
                Text(personality.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MochiTheme.textLight)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MochiTheme.primary)
                }
            }

            Text(personality.description)
                .font(.system(size: 12))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .lineLimit(2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? MochiTheme.primary.opacity(0.08) : MochiTheme.backgroundLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? MochiTheme.primary.opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture {
            appState.currentPersonality = personality
            appState.saveConfig()
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsSection("Fréquence des relances") {
                    VStack(alignment: .leading, spacing: 8) {
                        radioOption("zen", label: "Zen (peu de relances)")
                        radioOption("normal", label: "Normal")
                        radioOption("intense", label: "Intense (beaucoup de relances)")
                    }
                }

                settingsSection("Briefing matinal") {
                    Toggle(isOn: $appState.morningBriefingEnabled) {
                        Text("Activer le briefing matinal")
                            .font(.system(size: 13))
                            .foregroundStyle(MochiTheme.textLight)
                    }
                    .tint(MochiTheme.primary)

                    if appState.morningBriefingEnabled {
                        HStack {
                            Text("Heure du briefing")
                                .font(.system(size: 13))
                                .foregroundStyle(MochiTheme.textLight)
                            Spacer()
                            Picker("", selection: $appState.morningBriefingHour) {
                                ForEach(6..<12, id: \.self) { hour in
                                    Text("\(hour)h00").tag(hour)
                                }
                            }
                            .frame(width: 100)
                        }
                    }
                }

                settingsSection("Streak") {
                    Toggle(isOn: $appState.weekendsProtected) {
                        Text("Week-ends ne cassent pas le streak")
                            .font(.system(size: 13))
                            .foregroundStyle(MochiTheme.textLight)
                    }
                    .tint(MochiTheme.primary)
                }
            }
            .padding(20)
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
    }

    private func radioOption(_ value: String, label: String) -> some View {
        Button {
            appState.notificationFrequency = value
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(appState.notificationFrequency == value ? MochiTheme.primary : Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(appState.notificationFrequency == value ? MochiTheme.primary : Color.gray.opacity(0.3), lineWidth: 1.5))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(MochiTheme.textLight)
            }
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
            VStack(alignment: .leading, spacing: 20) {
                settingsSection("Connexion Notion") {
                    if isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connecté à Notion")
                                .font(.system(size: 13))
                                .foregroundStyle(MochiTheme.textLight)
                        }

                        settingsField("ID de la base de données") {
                            TextField("ID", text: $databaseId)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundStyle(MochiTheme.textLight)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MochiTheme.backgroundLight)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                                )
                        }

                        Button {
                            disconnectNotion()
                        } label: {
                            Text("Déconnecter")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    } else {
                        settingsField("Token d'intégration") {
                            SecureField("Token Notion", text: $notionToken)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundStyle(MochiTheme.textLight)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(MochiTheme.backgroundLight)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                                )
                        }

                        Button {
                            connectNotion()
                        } label: {
                            Text("Connecter")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(notionToken.isEmpty ? MochiTheme.primary.opacity(0.4) : MochiTheme.primary))
                        }
                        .buttonStyle(.plain)
                        .disabled(notionToken.isEmpty)
                    }
                }

                settingsSection("Synchronisation") {
                    Text("La synchronisation bidirectionnelle sera configurée après connexion.")
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                }
            }
            .padding(20)
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
            VStack(alignment: .leading, spacing: 20) {
                settingsSection("Raccourcis globaux") {
                    shortcutRow("Ouvrir/fermer le chat", shortcut: "⌘⇧M")
                    shortcutRow("Mini-panel menubar", shortcut: "⌘⇧N")
                    shortcutRow("Ajout rapide de tâche", shortcut: "⌘⇧A")
                }

                Text("La configuration personnalisée des raccourcis sera disponible dans une version future.")
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }
            .padding(20)
        }
    }

    private func shortcutRow(_ label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight)
            Spacer()
            Text(shortcut)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(MochiTheme.textLight.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MochiTheme.backgroundLight)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.15)))
                )
        }
    }
}

// MARK: - Shared Settings Helpers

private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(MochiTheme.textLight)
            .textCase(.uppercase)
            .tracking(0.5)

        VStack(alignment: .leading, spacing: 10) {
            content()
        }
    }
}

private func settingsField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 5) {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(MochiTheme.textLight.opacity(0.5))
        content()
    }
}
