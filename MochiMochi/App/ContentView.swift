import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showMochiPanel: Bool = true
    @State private var mochiToggleHovered: Bool = false

    var body: some View {
        if !appState.isOnboardingComplete {
            OnboardingView()
        } else {
            mainView
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            NavigationBarView(selectedTab: $appState.selectedTab)

            Group {
                switch appState.selectedTab {
                case .dashboard:
                    dashboardLayout
                case .tasks:
                    TasksTrackingView()
                case .shop:
                    ShopView()
                case .notes:
                    NotesView()
                case .meetings:
                    MeetingsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
        .background(MochiTheme.backgroundLight)
        .task {
            await appState.sendSilentGreeting()
            await appState.announceUpdateIfNeeded()
        }
    }

    // MARK: - Dashboard Layout

    private var dashboardLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            TodaysFocusView()
                .frame(minWidth: 280, maxWidth: 320)
                .padding(.trailing, 16)

            ChatView()

            mochiToggleStrip

            if showMochiPanel {
                MochiView()
                    .frame(minWidth: 280, maxWidth: 320)
                    .padding(.leading, 12)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMochiPanel)
    }

    // MARK: - Mochi Toggle

    private var mochiToggleStrip: some View {
        Button {
            toggleMochiPanel()
        } label: {

            ZStack {
                if showMochiPanel {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            mochiToggleHovered
                                ? MochiTheme.primary
                                : MochiTheme.textLight.opacity(0.25)
                        )
                } else {
                    Image(systemName: "chevron.compact.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            mochiToggleHovered
                                ? MochiTheme.primary
                                : MochiTheme.textLight.opacity(0.25)
                        )
                }
            }
            .frame(width: 28, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        mochiToggleHovered
                            ? (showMochiPanel ? Color.gray.opacity(0.1) : MochiTheme.primary.opacity(0.12))
                            : (showMochiPanel ? Color.gray.opacity(0.04) : MochiTheme.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                mochiToggleHovered
                                    ? MochiTheme.primary.opacity(0.2)
                                    : Color.gray.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                mochiToggleHovered = hovering
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.leading, 8)
    }

    private func toggleMochiPanel() {
        if showMochiPanel {
            // Mochi est triste de partir
            appState.setTemporaryEmotion(.sad, duration: 3)
            // Laisser Mochi montrer sa tristesse, puis cacher
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMochiPanel = false
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showMochiPanel = true
            }
            // Mochi est content de revenir
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.setTemporaryEmotion(.excited, duration: 4)
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppState())
}
