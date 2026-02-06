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
            NavigationBarView(selectedTab: $appState.selectedTab)

            Group {
                switch appState.selectedTab {
                case .dashboard:
                    dashboardLayout
                case .tasks:
                    TasksTrackingView()
                case .shop:
                    ShopView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
        .background(MochiTheme.backgroundLight)
    }

    private var dashboardLayout: some View {
        HStack(spacing: 16) {
            TodaysFocusView()
                .frame(minWidth: 280, maxWidth: 320)

            ChatView()

            MochiView()
                .frame(minWidth: 280, maxWidth: 320)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppState())
}
