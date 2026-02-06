import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var mochiName = "Mochi"
    @State private var selectedPersonality: Personality = .kawaii
    @State private var selectedColor: MochiColor = .pink
    @State private var claudeCodeInstalled = false
    @State private var isCheckingClaude = false
    @State private var storagePath: URL = MarkdownStorage.storedBaseDirectory
    @State private var existingConfigFound = false

    private let totalSteps = 8

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding()

            Divider()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: claudeCodeStep
                case 2: storagePathStep
                case 3: nameStep
                case 4: colorStep
                case 5: personalityStep
                case 6: shortcutStep
                case 7: summaryStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)

            Divider()

            // Navigation buttons
            navigationButtons
                .padding()
        }
        .frame(width: 650, height: 580)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            MochiAvatarView(
                emotion: .excited,
                color: .white,
                equippedItems: [],
                size: 120
            )

            Text("Bienvenue dans Mochi Mochi !")
                .font(.largeTitle.bold())

            Text("Ton compagnon de productivite qui ne t'oublie jamais.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Configurons ton Mochi en quelques etapes.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var claudeCodeStep: some View {
        VStack(spacing: 20) {
            Text("Verification de Claude Code")
                .font(.title2.bold())

            if isCheckingClaude {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Verification en cours...")
                    .foregroundStyle(.secondary)
            } else if claudeCodeInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Claude Code est installe et fonctionnel !")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Claude Code n'a pas ete detecte.")
                    .foregroundStyle(.red)
                Text("Installe Claude Code depuis le terminal :\nnpm install -g @anthropic-ai/claude-code")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Reverifier") {
                    checkClaudeCode()
                }
            }
        }
        .onAppear {
            checkClaudeCode()
        }
    }

    private var storagePathStep: some View {
        VStack(spacing: 20) {
            Text("Ou stocker les fichiers memoire ?")
                .font(.title2.bold())

            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Mochi Mochi sauvegarde tes taches, objectifs et sessions dans des fichiers Markdown locaux.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            // Current path display
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(Color.accentColor)
                Text(storagePath.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(12)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            HStack(spacing: 12) {
                Button("Utiliser le dossier par defaut") {
                    let defaultPath = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".mochi-mochi")
                    storagePath = defaultPath
                    checkExistingConfig()
                }
                .buttonStyle(.bordered)

                Button("Choisir un dossier...") {
                    chooseStorageFolder()
                }
                .buttonStyle(.bordered)
            }

            if existingConfigFound {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Configuration existante detectee ! Tes reglages seront restaures.")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }

            Text("Tous les fichiers restent sur ta machine et sont lisibles manuellement.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            checkExistingConfig()
        }
    }

    private var nameStep: some View {
        VStack(spacing: 20) {
            Text("Comment s'appelle ton Mochi ?")
                .font(.title2.bold())

            MochiAvatarView(
                emotion: .happy,
                color: selectedColor,
                equippedItems: [],
                size: 100
            )

            TextField("Nom du Mochi", text: $mochiName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .multilineTextAlignment(.center)
                .font(.title3)

            Text("Tu pourras le changer dans les reglages.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var personalityStep: some View {
        VStack(spacing: 16) {
            Text("Choisis la personnalite de \(mochiName)")
                .font(.title2.bold())

            MochiAvatarView(
                emotion: personalityEmotion(selectedPersonality),
                color: selectedColor,
                equippedItems: [],
                size: 90
            )
            .animation(.spring(response: 0.4), value: selectedPersonality)

            Text("\(selectedPersonality.emoji) \(selectedPersonality.displayName)")
                .font(.headline)
                .animation(.easeInOut, value: selectedPersonality)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 10) {
                    ForEach(Personality.allCases, id: \.self) { personality in
                        personalityCard(personality)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func personalityEmotion(_ personality: Personality) -> MochiEmotion {
        switch personality {
        case .kawaii: return .happy
        case .sensei: return .focused
        case .pote: return .idle
        case .butler: return .proud
        case .coach: return .excited
        case .sage: return .idle
        case .chat: return .sleeping
        case .heroique: return .proud
        }
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = selectedPersonality == personality

        return HStack(alignment: .top, spacing: 12) {
            Text(personality.emoji)
                .font(.title)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(personality.displayName)
                    .font(.subheadline.bold())
                Text(personality.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPersonality = personality
            }
        }
    }

    private let onboardingColors: [MochiColor] = [.pink, .teal]

    private var colorStep: some View {
        VStack(spacing: 20) {
            Text("Choisis la couleur de \(mochiName)")
                .font(.title2.bold())

            MochiAvatarView(
                emotion: .happy,
                color: selectedColor,
                equippedItems: [],
                size: 100
            )
            .animation(.easeInOut(duration: 0.3), value: selectedColor)

            HStack(spacing: 16) {
                ForEach(onboardingColors, id: \.self) { color in
                    colorOption(color)
                }
            }

            Text("D'autres couleurs se debloquent dans la boutique au fil de ta progression !")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func colorOption(_ color: MochiColor) -> some View {
        let isSelected = selectedColor == color

        return VStack(spacing: 6) {
            Circle()
                .fill(swiftUIColor(for: color))
                .frame(width: 50, height: 50)
                .shadow(color: swiftUIColor(for: color).opacity(0.4), radius: isSelected ? 6 : 0)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)

            Text(color.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
        }
        .onTapGesture {
            selectedColor = color
        }
    }

    private var shortcutStep: some View {
        VStack(spacing: 20) {
            Text("Raccourci global")
                .font(.title2.bold())

            Text("Utilise ce raccourci pour ouvrir Mochi Mochi depuis n'importe ou :")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                keyCapView("⌘")
                keyCapView("⇧")
                keyCapView("M")
            }

            Text("Tu pourras le personnaliser dans les reglages.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func keyCapView(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 24, design: .rounded).bold())
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 2)
            )
    }

    private var summaryStep: some View {
        VStack(spacing: 20) {
            Text("Tout est pret !")
                .font(.title.bold())

            MochiAvatarView(
                emotion: .proud,
                color: selectedColor,
                equippedItems: [],
                size: 100
            )

            VStack(alignment: .leading, spacing: 10) {
                summaryRow(label: "Nom", value: mochiName)
                Divider()
                summaryRow(label: "Personnalite", value: "\(selectedPersonality.emoji) \(selectedPersonality.displayName)")
                Divider()
                summaryRow(label: "Couleur", value: selectedColor.displayName)
                Divider()
                summaryRow(label: "Memoire", value: storagePath.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                Divider()
                summaryRow(label: "Raccourci", value: "⌘⇧M")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .frame(width: 350)

            Text("\(mochiName) est pret a t'accompagner !")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Precedent") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("Suivant") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentStep == 1 && !claudeCodeInstalled)
            } else {
                Button("Commencer !") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Actions

    private func checkClaudeCode() {
        isCheckingClaude = true
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = ["claude"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let found: Bool
            do {
                try process.run()
                process.waitUntilExit()
                found = process.terminationStatus == 0
            } catch {
                found = false
            }

            DispatchQueue.main.async {
                claudeCodeInstalled = found
                isCheckingClaude = false
            }
        }
    }

    private func completeOnboarding() {
        // Save storage path and reinitialize services
        MarkdownStorage.setStoragePath(storagePath)

        appState.mochi.name = mochiName
        appState.mochi.color = selectedColor
        appState.currentPersonality = selectedPersonality
        appState.isOnboardingComplete = true
        appState.saveState()
    }

    private func chooseStorageFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choisir le dossier de memoire Mochi Mochi"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            storagePath = url.appendingPathComponent(".mochi-mochi")
            checkExistingConfig()
        }
    }

    private func checkExistingConfig() {
        let configFile = storagePath.appendingPathComponent("config.md")
        guard FileManager.default.fileExists(atPath: configFile.path),
              let content = try? String(contentsOf: configFile, encoding: .utf8) else {
            existingConfigFound = false
            return
        }

        let storage = MarkdownStorage(baseDirectory: storagePath)
        let config = storage.parseConfigFromMarkdown(content)

        // Pre-fill onboarding fields from existing config
        mochiName = config.mochiName
        selectedPersonality = config.personality
        selectedColor = config.mochiColor
        existingConfigFound = true

        // Also try to restore gamification and tasks
        if let mochiContent = storage.read(file: "state/mochi.md") {
            let gamification = storage.parseGamificationFromMarkdown(mochiContent)
            appState.gamification = gamification
        }
        if let tasksContent = storage.read(file: "state/current.md") {
            let tasks = storage.parseTasksFromMarkdown(tasksContent)
            appState.tasks = tasks
        }
    }

    private func swiftUIColor(for mochiColor: MochiColor) -> Color {
        switch mochiColor {
        case .white: return Color(red: 0.96, green: 0.95, blue: 0.93)
        case .pink: return Color(red: 1.0, green: 0.8, blue: 0.85)
        case .teal: return Color(red: 0.55, green: 0.83, blue: 0.78)
        case .matcha: return Color(red: 0.75, green: 0.88, blue: 0.73)
        case .skyBlue: return Color(red: 0.75, green: 0.87, blue: 1.0)
        case .golden: return Color(red: 1.0, green: 0.9, blue: 0.6)
        }
    }
}
