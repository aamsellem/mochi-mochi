import Foundation
import Carbon.HIToolbox
import AppKit

// MARK: - Errors

enum KeyboardShortcutError: LocalizedError {
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let shortcut):
            return "Impossible d'enregistrer le raccourci \(shortcut)."
        }
    }
}

// MARK: - Keyboard Shortcut Service

final class KeyboardShortcutService {
    var onToggleMainWindow: (() -> Void)?
    var onToggleMiniPanel: (() -> Void)?
    var onQuickAdd: (() -> Void)?

    private var monitors: [Any] = []

    // MARK: - Register

    func registerGlobalShortcuts() {
        unregisterAll()

        // Cmd+Shift+M: Toggle main window
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .shift]) else { return }
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "m":
                self?.onToggleMainWindow?()
            case "n":
                self?.onToggleMiniPanel?()
            case "a":
                self?.onQuickAdd?()
            default:
                break
            }
        } {
            monitors.append(monitor)
        }
    }

    // MARK: - Unregister

    func unregisterAll() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
    }

    deinit {
        unregisterAll()
    }
}
