import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var mochiName = "Mochi"
    @State private var selectedPersonality: Personality = .kawaii
    @State private var selectedColor: MochiColor = .white
    @State private var claudeCodeInstalled = false
    @State private var isCheckingClaude = false

    private let totalSteps = 7

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
                case 2: nameStep
                case 3: personalityStep
                case 4: colorStep
                case 5: shortcutStep
                case 6: summaryStep
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
        .frame(width: 600, height: 500)
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

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 10) {
                    ForEach(Personality.allCases, id: \.self) { personality in
                        personalityCard(personality)
                    }
                }
            }
        }
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let isSelected = selectedPersonality == personality

        return HStack(spacing: 10) {
            Text(personality.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(personality.displayName)
                    .font(.subheadline.bold())
                Text(personality.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPersonality = personality
            }
        }
    }

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
                ForEach(MochiColor.allCases, id: \.self) { color in
                    colorOption(color)
                }
            }
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
        appState.mochi.name = mochiName
        appState.mochi.color = selectedColor
        appState.currentPersonality = selectedPersonality
        appState.isOnboardingComplete = true
        appState.saveState()
    }

    private func swiftUIColor(for mochiColor: MochiColor) -> Color {
        switch mochiColor {
        case .white: return Color(red: 0.96, green: 0.95, blue: 0.93)
        case .pink: return Color(red: 1.0, green: 0.8, blue: 0.85)
        case .matcha: return Color(red: 0.75, green: 0.88, blue: 0.73)
        case .skyBlue: return Color(red: 0.75, green: 0.87, blue: 1.0)
        case .golden: return Color(red: 1.0, green: 0.9, blue: 0.6)
        }
    }
}
