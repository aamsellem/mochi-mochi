import SwiftUI

struct MochiAvatarView: View {
    let emotion: MochiEmotion
    let color: MochiColor
    let equippedItems: [ShopItem]
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            // Body
            mochiBody

            // Face
            mochiFace
                .offset(y: -size * 0.05)

            // Equipped accessories overlay
            equippedAccessories
        }
        .frame(width: size, height: size)
    }

    // MARK: - Body

    private var mochiBody: some View {
        Ellipse()
            .fill(bodyGradient)
            .frame(width: size * 0.85, height: size * 0.75)
            .shadow(color: bodyColor.opacity(0.3), radius: 8, y: 4)
            .overlay(
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.4), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.35)
                    .offset(x: -size * 0.1, y: -size * 0.1)
            )
    }

    private var bodyGradient: LinearGradient {
        LinearGradient(
            colors: [bodyColor.opacity(0.9), bodyColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var bodyColor: Color {
        switch color {
        case .white: return Color(red: 0.96, green: 0.95, blue: 0.93)
        case .pink: return Color(red: 1.0, green: 0.8, blue: 0.85)
        case .matcha: return Color(red: 0.75, green: 0.88, blue: 0.73)
        case .skyBlue: return Color(red: 0.75, green: 0.87, blue: 1.0)
        case .golden: return Color(red: 1.0, green: 0.9, blue: 0.6)
        }
    }

    // MARK: - Face

    @ViewBuilder
    private var mochiFace: some View {
        switch emotion {
        case .idle:
            idleFace
        case .happy:
            happyFace
        case .excited:
            excitedFace
        case .focused:
            focusedFace
        case .sleeping:
            sleepingFace
        case .worried:
            worriedFace
        case .sad:
            sadFace
        case .proud:
            proudFace
        case .thinking:
            thinkingFace
        }
    }

    private var idleFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                mochiEye
                mochiEye
            }
            mochiMouth(smile: true)
        }
    }

    private var happyFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                happyEye
                happyEye
            }
            mochiMouth(smile: true, wide: true)
        }
    }

    private var excitedFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                starEye
                starEye
            }
            mochiMouth(smile: true, wide: true, open: true)
        }
    }

    private var focusedFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                determinedEye(left: true)
                determinedEye(left: false)
            }
            mochiMouth(smile: false, flat: true)
        }
    }

    private var sleepingFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                closedEye
                closedEye
            }
            .overlay(
                Text("Zzz")
                    .font(.system(size: size * 0.1, weight: .bold))
                    .foregroundStyle(.secondary)
                    .offset(x: size * 0.25, y: -size * 0.12)
            )
            mochiMouth(smile: false, flat: true)
        }
    }

    private var worriedFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                worriedEye
                worriedEye
            }
            mochiMouth(smile: false, wavy: true)
        }
        .overlay(
            // Sweat drop
            Circle()
                .fill(Color.cyan.opacity(0.5))
                .frame(width: size * 0.05, height: size * 0.07)
                .offset(x: size * 0.22, y: -size * 0.08)
        )
    }

    private var sadFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                sadEye
                sadEye
            }
            mochiMouth(smile: false, sad: true)
        }
        .overlay(
            // Tear
            Ellipse()
                .fill(Color.cyan.opacity(0.6))
                .frame(width: size * 0.03, height: size * 0.06)
                .offset(x: -size * 0.06, y: size * 0.04)
        )
    }

    private var proudFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                happyEye
                happyEye
            }
            mochiMouth(smile: true, wide: true)
        }
        .overlay(
            // Golden aura
            Circle()
                .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                .frame(width: size * 0.95, height: size * 0.85)
        )
    }

    private var thinkingFace: some View {
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.15) {
                mochiEye
                mochiEye
                    .offset(y: -size * 0.02)
            }
            mochiMouth(smile: false, flat: true)
        }
        .overlay(
            // Thinking dots
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(.secondary)
                        .frame(width: size * 0.03)
                }
            }
            .offset(x: size * 0.2, y: -size * 0.15)
        )
    }

    // MARK: - Eye Components

    private var mochiEye: some View {
        Ellipse()
            .fill(.primary)
            .frame(width: size * 0.07, height: size * 0.09)
    }

    private var happyEye: some View {
        // Upside down U shape for happy eyes
        HalfCircleShape()
            .stroke(.primary, lineWidth: size * 0.025)
            .frame(width: size * 0.08, height: size * 0.05)
    }

    private var starEye: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.08))
            .foregroundStyle(.yellow)
    }

    private func determinedEye(left: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.primary)
                .frame(width: size * 0.09, height: size * 0.02)
                .rotationEffect(.degrees(left ? -10 : 10))
            Ellipse()
                .fill(.primary)
                .frame(width: size * 0.06, height: size * 0.07)
        }
    }

    private var closedEye: some View {
        HalfCircleShape()
            .rotation(.degrees(180))
            .stroke(.primary, lineWidth: size * 0.025)
            .frame(width: size * 0.08, height: size * 0.04)
    }

    private var worriedEye: some View {
        Ellipse()
            .fill(.primary)
            .frame(width: size * 0.08, height: size * 0.1)
    }

    private var sadEye: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(.primary)
                .frame(width: size * 0.09, height: size * 0.015)
                .rotationEffect(.degrees(10))
            Ellipse()
                .fill(.primary)
                .frame(width: size * 0.06, height: size * 0.07)
        }
    }

    // MARK: - Mouth Components

    private func mochiMouth(
        smile: Bool = true,
        wide: Bool = false,
        open: Bool = false,
        flat: Bool = false,
        wavy: Bool = false,
        sad: Bool = false
    ) -> some View {
        Group {
            if open {
                Ellipse()
                    .fill(.primary)
                    .frame(width: size * 0.06, height: size * 0.05)
            } else if flat {
                Rectangle()
                    .fill(.primary)
                    .frame(width: size * (wide ? 0.1 : 0.06), height: size * 0.015)
            } else if wavy {
                WavyLineShape()
                    .stroke(.primary, lineWidth: size * 0.02)
                    .frame(width: size * 0.08, height: size * 0.03)
            } else if sad {
                HalfCircleShape()
                    .rotation(.degrees(180))
                    .stroke(.primary, lineWidth: size * 0.02)
                    .frame(width: size * 0.07, height: size * 0.03)
            } else {
                HalfCircleShape()
                    .stroke(.primary, lineWidth: size * 0.02)
                    .frame(width: size * (wide ? 0.1 : 0.07), height: size * 0.03)
            }
        }
    }

    // MARK: - Equipped Items

    @ViewBuilder
    private var equippedAccessories: some View {
        let hats = equippedItems.filter { $0.category == .hat }
        let accessories = equippedItems.filter { $0.category == .accessory }

        if let hat = hats.first {
            Text(hatEmoji(for: hat.name))
                .font(.system(size: size * 0.2))
                .offset(y: -size * 0.35)
        }

        if let accessory = accessories.first {
            Text(accessoryEmoji(for: accessory.name))
                .font(.system(size: size * 0.12))
                .offset(x: size * 0.3, y: -size * 0.05)
        }
    }

    private func hatEmoji(for name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("couronne"): return "👑"
        case let n where n.contains("beret"): return "🎨"
        case let n where n.contains("sorcier"): return "🧙"
        case let n where n.contains("ninja"): return "🥷"
        case let n where n.contains("casquette"): return "🧢"
        default: return "🎩"
        }
    }

    private func accessoryEmoji(for name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("lunettes"): return "🤓"
        case let n where n.contains("echarpe"): return "🧣"
        case let n where n.contains("cape"): return "🦸"
        case let n where n.contains("ailes"): return "🪽"
        case let n where n.contains("noeud"): return "🎀"
        default: return "✨"
        }
    }
}

// MARK: - Custom Shapes

struct HalfCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        return path
    }
}

struct WavyLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.25, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.75, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.75, y: rect.maxY)
        )
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            MochiAvatarView(emotion: .idle, color: .white, equippedItems: [])
            MochiAvatarView(emotion: .happy, color: .pink, equippedItems: [])
            MochiAvatarView(emotion: .excited, color: .matcha, equippedItems: [])
        }
        HStack(spacing: 20) {
            MochiAvatarView(emotion: .sleeping, color: .skyBlue, equippedItems: [])
            MochiAvatarView(emotion: .worried, color: .white, equippedItems: [])
            MochiAvatarView(emotion: .sad, color: .pink, equippedItems: [])
        }
    }
    .padding()
}
