import SwiftUI

struct MochiView: View {
    @EnvironmentObject var appState: AppState

    @State private var bounceOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var emotionScale: CGFloat = 1.0
    @State private var thinkingWobble: Double = 0
    @State private var thinkingScale: CGFloat = 1.0
    @State private var isThinking = false
    @State private var showCustomize = false
    @State private var idleActionText: String? = nil
    @State private var idleActionOpacity: Double = 0
    @State private var idleTimer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                companionCard
                statsGrid
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section 1: My Companion Card

    private var companionCard: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Mon Compagnon")
                    .font(.headline.bold())
                    .foregroundStyle(MochiTheme.textLight)
                Spacer()
                Button {
                    showCustomize.toggle()
                } label: {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MochiTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(MochiTheme.primary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Avatar + idle action bubble
            ZStack {
                MochiAvatarView(
                    emotion: appState.mochi.emotion,
                    color: appState.mochi.color,
                    equippedItems: appState.mochi.equippedItems,
                    size: 100
                )
                .scaleEffect(isThinking ? thinkingScale : emotionScale)
                .offset(y: bounceOffset)
                .rotationEffect(.degrees(isThinking ? thinkingWobble : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: appState.mochi.emotion)
                .onChange(of: appState.mochi.emotion) { _, newEmotion in
                    reactToEmotion(newEmotion)
                    if newEmotion == .idle {
                        startIdleActions()
                    } else {
                        dismissIdleAction()
                    }
                }
                .onAppear {
                    startIdleAnimation()
                    startIdleActions()
                }
                .onDisappear {
                    idleTimer?.invalidate()
                    idleTimer = nil
                }

                // Idle action floating bubble
                if let action = idleActionText {
                    Text(action)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(MochiTheme.textLight.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        )
                        .offset(y: -65)
                        .opacity(idleActionOpacity)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }

            // Name
            Text(appState.mochi.name)
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)

            // Level + Emotion
            Text("Niveau \(appState.gamification.level) \u{2022} \(emotionLabel(appState.mochi.emotion))")
                .font(.subheadline)
                .foregroundStyle(MochiTheme.textLight.opacity(0.6))

            // Customize sheet
            .sheet(isPresented: $showCustomize) {
                MochiCustomizeSheet()
                    .environmentObject(appState)
            }

            // XP Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(MochiTheme.primary)
                            .frame(width: geo.size.width * appState.gamification.xpProgress)
                            .animation(.easeInOut(duration: 0.5), value: appState.gamification.xpProgress)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formattedNumber(appState.gamification.currentXP)) / \(formattedNumber(appState.gamification.xpRequiredForCurrentLevel))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL)
                .fill(
                    LinearGradient(
                        colors: [Color.white, MochiTheme.accent.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }

    // MARK: - Section 2: Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                emoji: "🍙",
                iconColor: .orange,
                value: "\(appState.gamification.riceGrains)",
                label: "GRAINS DE RIZ"
            )
            statCard(
                icon: "bolt.fill",
                iconColor: .blue,
                value: "\(energyPercent)%",
                label: "ENERGIE"
            )
        }
    }

    private func statCard(icon: String? = nil, emoji: String? = nil, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 18))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }
            }

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(MochiTheme.textLight)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(MochiTheme.textLight.opacity(0.5))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadius2XL)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadius2XL)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - Computed Properties

    private var energyPercent: Int {
        min(100, appState.gamification.streakDays * 10)
    }

    private func emotionLabel(_ emotion: MochiEmotion) -> String {
        switch emotion {
        case .idle: return "Tranquille"
        case .happy: return "Content"
        case .excited: return "Excite"
        case .focused: return "Concentre"
        case .sleeping: return "Dort"
        case .worried: return "Inquiet"
        case .sad: return "Triste"
        case .proud: return "Fier"
        case .thinking: return "Reflechit"
        }
    }

    private func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // MARK: - Animation

    private func startIdleAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -4
        }
    }

    private func startThinkingAnimation() {
        isThinking = true
        // Wobble rotation
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            thinkingWobble = 5
        }
        // Pulse scale
        withAnimation(
            .easeInOut(duration: 0.7)
            .repeatForever(autoreverses: true)
        ) {
            thinkingScale = 1.08
        }
        // Faster bounce
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -10
        }
    }

    private func stopThinkingAnimation() {
        isThinking = false
        thinkingWobble = 0
        thinkingScale = 1.0
        // Retour au bounce idle
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -4
        }
    }

    // MARK: - Idle Actions

    private func startIdleActions() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
            Task { @MainActor in
                guard appState.mochi.emotion == .idle, !appState.isLoading else { return }
                showRandomIdleAction()
                // Reschedule with random interval for natural feel
                idleTimer?.invalidate()
                idleTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 8...15), repeats: true) { _ in
                    Task { @MainActor in
                        guard appState.mochi.emotion == .idle, !appState.isLoading else { return }
                        showRandomIdleAction()
                    }
                }
            }
        }
    }

    private func showRandomIdleAction() {
        let actions = appState.currentPersonality.idleMessages
        guard let action = actions.randomElement() else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            idleActionText = action
            idleActionOpacity = 1.0
        }

        // Personality-specific micro-animation
        playIdleMicroAnimation()

        // Dismiss after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            dismissIdleAction()
        }
    }

    private func dismissIdleAction() {
        withAnimation(.easeOut(duration: 0.4)) {
            idleActionOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            idleActionText = nil
        }
    }

    private func playIdleMicroAnimation() {
        switch appState.currentPersonality {
        case .kawaii:
            // Petit sautillement joyeux
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) {
                emotionScale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    emotionScale = 1.0
                }
            }
        case .coach:
            // Mouvement energique rapide
            withAnimation(.spring(response: 0.15, dampingFraction: 0.2)) {
                emotionScale = 1.15
                bounceOffset = -12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    emotionScale = 1.0
                    bounceOffset = -4
                }
            }
        case .chat:
            // Rotation hautaine
            withAnimation(.easeInOut(duration: 0.6)) {
                thinkingWobble = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    thinkingWobble = 0
                }
            }
        case .heroique:
            // Pose heroique avec scale
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                emotionScale = 1.12
                bounceOffset = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    emotionScale = 1.0
                    bounceOffset = -4
                }
            }
        case .voyante:
            // Pulsation mystique lente
            withAnimation(.easeInOut(duration: 1.0)) {
                emotionScale = 1.08
                thinkingWobble = 3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    emotionScale = 1.0
                    thinkingWobble = 0
                }
            }
        case .butler:
            // Legere inclinaison polie
            withAnimation(.easeInOut(duration: 0.5)) {
                thinkingWobble = 5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    thinkingWobble = 0
                }
            }
        case .pote:
            // Petit wobble decontracte
            withAnimation(.easeInOut(duration: 0.4)) {
                thinkingWobble = 6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    thinkingWobble = -4
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    thinkingWobble = 0
                }
            }
        case .sensei:
            // Lente montee concentree
            withAnimation(.easeInOut(duration: 0.8)) {
                bounceOffset = -8
                emotionScale = 1.03
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    bounceOffset = -4
                    emotionScale = 1.0
                }
            }
        }
    }

    private func reactToEmotion(_ emotion: MochiEmotion) {
        if emotion == .thinking {
            startThinkingAnimation()
            return
        }

        if isThinking {
            stopThinkingAnimation()
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            emotionScale = emotion == .excited ? 1.15 : 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                emotionScale = 1.0
            }
        }
    }
}

#Preview {
    MochiView()
        .environmentObject(AppState())
        .frame(width: 280, height: 600)
}
