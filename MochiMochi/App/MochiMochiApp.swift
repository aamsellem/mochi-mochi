import SwiftUI
import AppKit
import Sparkle

@main
struct MochiMochiApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var updaterService = UpdaterService()

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .task {
                    guard appState.isOnboardingComplete else { return }
                    await appState.setupNotifications()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 700)

        // Menubar
        MenuBarExtra {
            MiniPanelView()
                .environmentObject(appState)
        } label: {
            let count = appState.tasks.filter { !$0.isCompleted }.count
            Image(nsImage: Self.mochiMenuBarIcon)
            Text("\(count)")
        }
        .menuBarExtraStyle(.window)

        // Settings
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(updaterService)
        }
    }

    /// Mochi-shaped template image for the menu bar (18x18 pt)
    private static let mochiMenuBarIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext

            // Body: cute rounded daifuku shape (wide ellipse, slightly flat bottom)
            let bodyPath = NSBezierPath()
            // Start from bottom-left, draw a slightly squished mochi body
            let cx: CGFloat = 9, cy: CGFloat = 9.5
            let rx: CGFloat = 7.5, ry: CGFloat = 6.5

            // Custom mochi shape — rounder on top, flatter bottom
            bodyPath.move(to: NSPoint(x: cx - rx, y: cy))
            // Bottom curve (flatter)
            bodyPath.curve(
                to: NSPoint(x: cx + rx, y: cy),
                controlPoint1: NSPoint(x: cx - rx, y: cy - ry * 0.7),
                controlPoint2: NSPoint(x: cx + rx, y: cy - ry * 0.7)
            )
            // Top curve (rounder, taller)
            bodyPath.curve(
                to: NSPoint(x: cx - rx, y: cy),
                controlPoint1: NSPoint(x: cx + rx, y: cy + ry),
                controlPoint2: NSPoint(x: cx - rx, y: cy + ry)
            )
            bodyPath.close()

            NSColor.black.setFill()
            bodyPath.fill()

            // Eyes: two small dots
            let eyeRadius: CGFloat = 1.2
            let eyeY: CGFloat = 10.5
            let leftEye = NSBezierPath(
                ovalIn: NSRect(x: 5.8 - eyeRadius, y: eyeY - eyeRadius,
                               width: eyeRadius * 2, height: eyeRadius * 2)
            )
            let rightEye = NSBezierPath(
                ovalIn: NSRect(x: 12.2 - eyeRadius, y: eyeY - eyeRadius,
                               width: eyeRadius * 2, height: eyeRadius * 2)
            )
            NSColor.white.setFill()
            leftEye.fill()
            rightEye.fill()

            // Mouth: tiny smile arc
            let smilePath = NSBezierPath()
            smilePath.move(to: NSPoint(x: 7.5, y: 8))
            smilePath.curve(
                to: NSPoint(x: 10.5, y: 8),
                controlPoint1: NSPoint(x: 8, y: 6.5),
                controlPoint2: NSPoint(x: 10, y: 6.5)
            )
            NSColor.white.setStroke()
            smilePath.lineWidth = 0.8
            smilePath.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }()
}
