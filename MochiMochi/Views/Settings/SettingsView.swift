import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PersonalitySettingsTab()
                .tabItem {
                    Label("Personnalite", systemImage: "face.smiling")
                }

            NotificationSettingsTab()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            NotionSettingsTab()
                .tabItem {
                    Label("Notion", systemImage: "link")
                }

            ShortcutSettingsTab()
                .tabItem {
                    Label("Raccourcis", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @EnvironmentObject var appState: AppState

    @State private var mochiName: String = ""
    @State private var selectedColor: MochiColor = .white

    var body: some View {
        Form {
            Section("Mochi") {
                TextField("Nom du Mochi", text: $mochiName)
                    .onAppear { mochiName = appState.mochi.name }
                    .onChange(of: mochiName) { _, newValue in
                        appState.mochi.name = newValue
                    }

                Picker("Couleur", selection: $selectedColor) {
                    ForEach(MochiColor.allCases, id: \.self) { color in
                        Text(color.displayName).tag(color)
                    }
                }
                .onAppear { selectedColor = appState.mochi.color }
                .onChange(of: selectedColor) { _, newValue in
                    appState.mochi.color = newValue
                }
            }

            Section("Application") {
                Button("Relancer l'onboarding") {
                    appState.isOnboardingComplete = false
                }
            }
        }
        .padding()
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
            .padding()
        }
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = appState.currentPersonality == personality

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(personality.emoji)
                    .font(.title2)
                Text(personality.displayName)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Text(personality.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            appState.currentPersonality = personality
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var frequency = "normal"
    @State private var morningBriefing = true
    @State private var briefingHour = 9
    @State private var weekendsOff = false

    var body: some View {
        Form {
            Section("Frequence des relances") {
                Picker("Frequence", selection: $frequency) {
                    Text("Zen (peu de relances)").tag("zen")
                    Text("Normal").tag("normal")
                    Text("Intense (beaucoup de relances)").tag("intense")
                }
                .pickerStyle(.radioGroup)
            }

            Section("Briefing matinal") {
                Toggle("Activer le briefing matinal", isOn: $morningBriefing)
                if morningBriefing {
                    Picker("Heure du briefing", selection: $briefingHour) {
                        ForEach(6..<12, id: \.self) { hour in
                            Text("\(hour)h00").tag(hour)
                        }
                    }
                }
            }

            Section("Streak") {
                Toggle("Week-ends ne cassent pas le streak", isOn: $weekendsOff)
            }
        }
        .padding()
    }
}

// MARK: - Notion Settings

struct NotionSettingsTab: View {
    @State private var notionToken = ""
    @State private var isConnected = false
    @State private var databaseId = ""

    var body: some View {
        Form {
            Section("Connexion Notion") {
                if isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connecte a Notion")
                    }
                    TextField("ID de la base de donnees", text: $databaseId)
                    Button("Deconnecter") {
                        disconnectNotion()
                    }
                    .foregroundStyle(.red)
                } else {
                    SecureField("Token d'integration Notion", text: $notionToken)
                    Button("Connecter") {
                        connectNotion()
                    }
                    .disabled(notionToken.isEmpty)
                }
            }

            Section("Synchronisation") {
                Text("La synchronisation bidirectionnelle sera configuree apres connexion.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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
    @State private var chatShortcut = "⌘⇧M"
    @State private var miniPanelShortcut = "⌘⇧N"
    @State private var quickAddShortcut = "⌘⇧A"

    var body: some View {
        Form {
            Section("Raccourcis globaux") {
                HStack {
                    Text("Ouvrir/fermer le chat")
                    Spacer()
                    Text(chatShortcut)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    Text("Mini-panel menubar")
                    Spacer()
                    Text(miniPanelShortcut)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    Text("Ajout rapide de tache")
                    Spacer()
                    Text(quickAddShortcut)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section {
                Text("La configuration personnalisee des raccourcis sera disponible dans une version future.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
