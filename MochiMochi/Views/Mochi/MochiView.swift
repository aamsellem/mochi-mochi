import SwiftUI

struct MochiView: View {
    @EnvironmentObject var appState: AppState

    @State private var bounceOffset: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Mochi avatar with idle bounce
            MochiAvatarView(
                emotion: appState.mochi.emotion,
                color: appState.mochi.color,
                equippedItems: appState.mochi.equippedItems,
                size: 160
            )
            .offset(y: bounceOffset)
            .onAppear { startIdleAnimation() }

            // Name
            Text(appState.mochi.name)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            // Level and XP bar
            levelSection

            Divider()
                .padding(.horizontal, 20)

            // Stats row
            statsRow

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Level Section

    private var levelSection: some View {
        VStack(spacing: 6) {
            Text("Niveau \(appState.gamification.level)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.1))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * appState.gamification.xpProgress)
                        .animation(.easeInOut(duration: 0.5), value: appState.gamification.xpProgress)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 20)

            Text("\(appState.gamification.currentXP) / \(appState.gamification.xpRequiredForCurrentLevel) XP")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 24) {
            statBadge(
                icon: "🍙",
                value: "\(appState.gamification.riceGrains)",
                label: "Grains"
            )

            statBadge(
                icon: "🔥",
                value: "\(appState.gamification.streakDays)j",
                label: "Streak"
            )
        }
        .padding(.horizontal, 20)
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Animation

    private func startIdleAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -6
        }
    }
}

#Preview {
    MochiView()
        .environmentObject(AppState())
        .frame(width: 280, height: 500)
}
