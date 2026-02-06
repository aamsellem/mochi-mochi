import SwiftUI

struct MochiView: View {
    @EnvironmentObject var appState: AppState

    @State private var bounceOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var emotionScale: CGFloat = 1.0
    @State private var showCustomize = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                companionCard
                statsGrid
                taskBacklogCard
            }
            .padding(16)
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

            // Avatar
            MochiAvatarView(
                emotion: appState.mochi.emotion,
                color: appState.mochi.color,
                equippedItems: appState.mochi.equippedItems,
                size: 100
            )
            .scaleEffect(emotionScale)
            .offset(y: bounceOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: appState.mochi.emotion)
            .onChange(of: appState.mochi.emotion) { _, newEmotion in
                reactToEmotion(newEmotion)
            }
            .onAppear { startIdleAnimation() }

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

    // MARK: - Section 3: Tâches en attente

    private var taskBacklogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("En attente")
                    .font(.headline.bold())
                    .foregroundStyle(MochiTheme.textLight)
                Spacer()
                Text("\(pendingTasks.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MochiTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(MochiTheme.primary.opacity(0.15)))
            }

            if pendingTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("Aucune tâche en attente")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(pendingTasks.prefix(5)) { task in
                    backlogTaskRow(task)
                }

                if pendingTasks.count > 5 {
                    Text("+ \(pendingTasks.count - 5) autres")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL)
                .fill(MochiTheme.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: MochiTheme.cornerRadiusXL)
                        .stroke(MochiTheme.primary.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func backlogTaskRow(_ task: MochiTask) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(backlogDotColor(task.priority))
                .frame(width: 7, height: 7)

            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MochiTheme.textLight)
                .lineLimit(1)

            Spacer()

            Button {
                appState.toggleInProgress(task)
            } label: {
                Text(task.isInProgress ? "En cours" : "Je suis dessus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(task.isInProgress ? .white : MochiTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(task.isInProgress ? MochiTheme.primary : MochiTheme.primary.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private func backlogDotColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return MochiTheme.errorRed
        case .normal: return MochiTheme.priorityNormal
        case .low: return MochiTheme.priorityLow
        }
    }

    // MARK: - Computed Properties

    private var energyPercent: Int {
        min(100, appState.gamification.streakDays * 10)
    }

    private var activeTaskCount: Int {
        appState.tasks.filter { !$0.isCompleted }.count
    }

    private var pendingTasks: [MochiTask] {
        appState.tasks.filter { !$0.isCompleted }
            .sorted { $0.priority.xpReward > $1.priority.xpReward }
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

    private func reactToEmotion(_ emotion: MochiEmotion) {
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
