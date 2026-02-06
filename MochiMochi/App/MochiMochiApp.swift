import SwiftUI

@main
struct MochiMochiApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 700)

        // Menubar
        MenuBarExtra {
            MiniPanelView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .pink)
            Text("\(appState.gamification.todayRemainingTasks)")
        }
        .menuBarExtraStyle(.window)

        // Settings
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
