import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !appState.isOnboardingComplete {
            OnboardingView()
        } else {
            mainView
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar
            Divider()

            // Tab content
            Group {
                switch appState.selectedTab {
                case .chat:
                    ChatView()
                case .dashboard:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var tabBar: some View {
        HStack {
            Text("🍡 Mochi Mochi")
                .font(.headline)

            Spacer()

            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    appState.selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(appState.selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
