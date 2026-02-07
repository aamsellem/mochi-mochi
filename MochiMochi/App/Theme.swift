import SwiftUI

enum MochiTheme {
    // MARK: - Couleurs principales
    static let primary = Color(hex: "FF9EAA")
    static let secondary = Color(hex: "3AA6B9")
    static let accent = Color(hex: "FFD0D0")

    // MARK: - Fonds
    static let backgroundLight = Color(hex: "F9F5F0")
    static let backgroundDark = Color(hex: "1F1D2B")
    static let surfaceLight = Color.white
    static let surfaceDark = Color(hex: "252836")

    // MARK: - Texte
    static let textLight = Color(hex: "4A4A4A")
    static let textDark = Color(hex: "E0E0E0")
    static let textSecondary = textLight.opacity(0.6)
    static let textPlaceholder = Color(hex: "9E9E9E")
    static let textDisabled = textLight.opacity(0.35)

    // MARK: - Pastels
    static let pastelYellow = Color(hex: "FFDFBA")
    static let pastelBlue = Color(hex: "BAE1FF")
    static let pastelGreen = Color(hex: "BAFFC9")

    // MARK: - Priorites
    static let priorityHigh = primary
    static let priorityNormal = Color(hex: "4ADE80")
    static let priorityLow = Color(hex: "F4A261")

    // MARK: - Semantiques
    static let successGreen = Color(hex: "22C55E")
    static let errorRed = Color(hex: "EF4444")

    // MARK: - Code Blocks
    static let codeBackground = Color(hex: "2D2D2D")
    static let codeText = Color(hex: "E0E0E0")

    // MARK: - Dimensions
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24
    static let cornerRadius2XL: CGFloat = 32
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
