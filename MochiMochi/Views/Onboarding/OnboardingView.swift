import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var userOccupation = ""
    @State private var userGoal = ""
    @State private var mochiName = "Mochi"
    @State private var selectedPersonality: Personality = .kawaii
    @State private var selectedColor: MochiColor = .pink
    @State private var claudeCodeInstalled = false
    @State private var isCheckingClaude = false
    @State private var storagePath: URL = MarkdownStorage.storedBaseDirectory
    @State private var existingConfigFound = false
    @State private var avatarBounce: CGFloat = 0

    private let totalSteps = 7

    private let occupations = [
        ("💻", "Developpeur"),
        ("🎨", "Designer"),
        ("📊", "Chef de projet"),
        ("🎓", "Etudiant"),
        ("✍️", "Freelance"),
        ("📈", "Entrepreneur"),
        ("🔬", "Chercheur"),
        ("🎯", "Autre"),
    ]

    private let goals = [
        ("🎯", "Mieux m'organiser", "Suivre mes taches et deadlines"),
        ("🚀", "Etre plus productif", "Optimiser mon temps et mon energie"),
        ("📚", "Apprendre des choses", "Avoir un compagnon de reflexion"),
        ("🧘", "Reduire mon stress", "Mieux gerer ma charge de travail"),
        ("🏆", "Atteindre mes objectifs", "Suivi long terme de mes goals"),
        ("🤝", "Avoir un compagnon", "Quelqu'un qui me connait et me motive"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: aboutYouStep
                case 2: goalStep
                case 3: mochiNameStep
                case 4: colorStep
                case 5: personalityStep
                case 6: summaryStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)

            navigationButtons
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
        }
        .frame(width: 680, height: 600)
        .background(MochiTheme.backgroundLight)
        .onAppear {
            checkClaudeCode()
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                avatarBounce = -6
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? MochiTheme.primary : MochiTheme.primary.opacity(0.15))
                    .frame(height: 5)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            MochiAvatarView(
                emotion: .excited,
                color: .pink,
                equippedItems: [],
                size: 130
            )
            .offset(y: avatarBounce)

            VStack(spacing: 10) {
                Text("Bienvenue dans Mochi Mochi")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(MochiTheme.textLight)

                Text("Ton compagnon de productivite qui ne t'oublie jamais.")
                    .font(.system(size: 15))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Text("Faisons connaissance en quelques etapes")
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))

            Spacer()
        }
    }

    // MARK: - Step 1: About You

    private var aboutYouStep: some View {
        VStack(spacing: 24) {
            stepHeader(icon: "person.fill", title: "Parle-nous de toi")

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment tu t'appelles ?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MochiTheme.textLight)

                    TextField("", text: $userName, prompt: Text("Ton prenom").foregroundColor(MochiTheme.textLight.opacity(0.3)))
                        .font(.system(size: 15))
                        .foregroundStyle(MochiTheme.textLight)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MochiTheme.surfaceLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(MochiTheme.primary.opacity(userName.isEmpty ? 0.15 : 0.4), lineWidth: 1.5)
                                )
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Qu'est-ce que tu fais ?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MochiTheme.textLight)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                        ForEach(occupations, id: \.1) { emoji, label in
                            chipButton(emoji: emoji, label: label, isSelected: userOccupation == label) {
                                withAnimation(.easeInOut(duration: 0.2)) { userOccupation = label }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(cardBackground)

            Spacer()
        }
    }

    // MARK: - Step 2: Goals

    private var goalStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                icon: "sparkles",
                title: userName.isEmpty ? "Qu'est-ce qui t'amene ?" : "Qu'est-ce qui t'amene, \(userName) ?"
            )

            VStack(spacing: 8) {
                ForEach(goals, id: \.1) { emoji, title, subtitle in
                    goalCard(emoji: emoji, title: title, subtitle: subtitle, isSelected: userGoal == title) {
                        withAnimation(.easeInOut(duration: 0.2)) { userGoal = title }
                    }
                }
            }
            .padding(20)
            .background(cardBackground)

            Spacer()
        }
    }

    // MARK: - Step 3: Mochi Name

    private var mochiNameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            stepHeader(icon: "heart.fill", title: "Nomme ton compagnon")

            MochiAvatarView(
                emotion: .happy,
                color: selectedColor,
                equippedItems: [],
                size: 110
            )
            .offset(y: avatarBounce)

            VStack(spacing: 12) {
                TextField("", text: $mochiName, prompt: Text("Nom du Mochi").foregroundColor(MochiTheme.textLight.opacity(0.3)))
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(MochiTheme.textLight)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .frame(width: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MochiTheme.surfaceLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(MochiTheme.primary.opacity(0.3), lineWidth: 1.5)
                            )
                    )

                Text("Tu pourras le changer dans les reglages")
                    .font(.system(size: 12))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.4))
            }

            Spacer()
        }
    }

    // MARK: - Step 4: Color

    private let onboardingColors: [MochiColor] = [.pink, .teal]

    private var colorStep: some View {
        VStack(spacing: 24) {
            Spacer()

            stepHeader(icon: "paintpalette.fill", title: "Choisis sa couleur")

            MochiAvatarView(
                emotion: .happy,
                color: selectedColor,
                equippedItems: [],
                size: 110
            )
            .offset(y: avatarBounce)
            .animation(.easeInOut(duration: 0.3), value: selectedColor)

            HStack(spacing: 20) {
                ForEach(onboardingColors, id: \.self) { color in
                    colorOption(color)
                }
            }

            Text("D'autres couleurs se debloquent en progressant")
                .font(.system(size: 12))
                .foregroundStyle(MochiTheme.textLight.opacity(0.4))

            Spacer()
        }
    }

    // MARK: - Step 5: Personality

    private var personalityStep: some View {
        VStack(spacing: 20) {
            stepHeader(icon: "theatermasks.fill", title: "Sa personnalite")

            HStack(spacing: 16) {
                MochiAvatarView(
                    emotion: personalityEmotion(selectedPersonality),
                    color: selectedColor,
                    equippedItems: [],
                    size: 70
                )
                .animation(.spring(response: 0.4), value: selectedPersonality)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedPersonality.emoji) \(selectedPersonality.displayName)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(MochiTheme.textLight)
                    Text(selectedPersonality.description)
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260))], spacing: 8) {
                    ForEach(Personality.allCases, id: \.self) { personality in
                        personalityCard(personality)
                    }
                }
            }
        }
    }

    // MARK: - Step 6: Summary

    private var summaryStep: some View {
        VStack(spacing: 24) {
            Spacer()

            MochiAvatarView(
                emotion: .proud,
                color: selectedColor,
                equippedItems: [],
                size: 100
            )
            .offset(y: avatarBounce)

            VStack(spacing: 6) {
                Text("Tout est pret !")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(MochiTheme.textLight)

                if !userName.isEmpty {
                    Text("\(mochiName) est pret a t'accompagner, \(userName) !")
                        .font(.system(size: 14))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                if !userName.isEmpty {
                    summaryRow(icon: "person.fill", label: "Toi", value: userName)
                    Divider().padding(.horizontal, 16)
                }
                if !userOccupation.isEmpty {
                    summaryRow(icon: "briefcase.fill", label: "Activite", value: userOccupation)
                    Divider().padding(.horizontal, 16)
                }
                summaryRow(icon: "heart.fill", label: "Compagnon", value: mochiName)
                Divider().padding(.horizontal, 16)
                summaryRow(icon: "theatermasks.fill", label: "Personnalite", value: "\(selectedPersonality.emoji) \(selectedPersonality.displayName)")
                Divider().padding(.horizontal, 16)
                summaryRow(icon: "paintpalette.fill", label: "Couleur", value: selectedColor.displayName)
                if !claudeCodeInstalled {
                    Divider().padding(.horizontal, 16)
                    summaryRow(icon: "exclamationmark.triangle.fill", label: "Claude Code", value: "Non detecte")
                }
            }
            .background(cardBackground)
            .frame(width: 380)

            Spacer()
        }
    }

    // MARK: - Shared Components

    private func stepHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(MochiTheme.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(MochiTheme.primary.opacity(0.12)))

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(MochiTheme.textLight)

            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(MochiTheme.surfaceLight)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func chipButton(emoji: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : MochiTheme.textLight)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? MochiTheme.primary : MochiTheme.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private func goalCard(emoji: String, title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(isSelected ? MochiTheme.primary.opacity(0.15) : Color.gray.opacity(0.06)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? MochiTheme.primary : MochiTheme.textLight)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MochiTheme.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? MochiTheme.primary.opacity(0.06) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? MochiTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = selectedPersonality == personality

        return HStack(alignment: .top, spacing: 10) {
            Text(personality.emoji)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(personality.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? MochiTheme.primary : MochiTheme.textLight)
                Text(personality.description)
                    .font(.system(size: 11))
                    .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MochiTheme.primary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? MochiTheme.primary.opacity(0.06) : MochiTheme.surfaceLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? MochiTheme.primary : Color.gray.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPersonality = personality
            }
        }
    }

    private func colorOption(_ color: MochiColor) -> some View {
        let isSelected = selectedColor == color

        return VStack(spacing: 8) {
            Circle()
                .fill(swiftUIColor(for: color))
                .frame(width: 56, height: 56)
                .shadow(color: swiftUIColor(for: color).opacity(isSelected ? 0.5 : 0.2), radius: isSelected ? 8 : 2)
                .overlay(
                    Circle()
                        .stroke(isSelected ? MochiTheme.primary : Color.clear, lineWidth: 3)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)

            Text(color.displayName)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? MochiTheme.primary : MochiTheme.textLight.opacity(0.6))
        }
        .onTapGesture {
            selectedColor = color
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(MochiTheme.primary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(MochiTheme.textLight.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Precedent")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(MochiTheme.textLight.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("Suivant")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(MochiTheme.primary)
                            .shadow(color: MochiTheme.primary.opacity(0.3), radius: 6, y: 2)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    HStack(spacing: 6) {
                        Text("C'est parti !")
                            .font(.system(size: 14, weight: .bold))
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(MochiTheme.primary)
                            .shadow(color: MochiTheme.primary.opacity(0.3), radius: 6, y: 2)
                    )
                }
                .buttonStyle(.plain)
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
        MarkdownStorage.setStoragePath(storagePath)

        appState.userName = userName
        appState.userOccupation = userOccupation
        appState.userGoal = userGoal
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

        mochiName = config.mochiName
        userName = config.userName
        userOccupation = config.userOccupation
        userGoal = config.userGoal
        selectedPersonality = config.personality
        selectedColor = config.mochiColor
        existingConfigFound = true

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
        case .grey: return Color(red: 0.72, green: 0.72, blue: 0.72)
        case .black: return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .nightBlue: return Color(red: 0.12, green: 0.15, blue: 0.35)
        case .violet: return Color(red: 0.7, green: 0.45, blue: 0.85)
        case .pride: return Color(red: 0.9, green: 0.36, blue: 0.36)
        }
    }
}
