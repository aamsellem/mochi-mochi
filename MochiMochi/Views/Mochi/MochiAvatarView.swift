import SwiftUI

struct MochiAvatarView: View {
    let emotion: MochiEmotion
    let color: MochiColor
    let equippedItems: [ShopItem]
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            // 1. Soft background circle for contrast
            Circle()
                .fill(bodyColor.opacity(0.15))
                .frame(width: size * 1.1, height: size * 1.1)

            // 2. Cape (si equipee) — DERRIERE le corps
            if hasEquipped("cape") {
                capeAccessory
            }

            // 3. Body
            mochiBody

            // 4. Echarpe (si equipee) — SUR le corps
            if hasEquipped("echarpe") {
                scarfAccessory
            }

            // 5. Face
            mochiFace
                .offset(y: -size * 0.05)

            // 6. Lunettes (si equipees) — SUR le visage
            if hasEquipped("lunettes") {
                glassesAccessory
            }

            // 7. Noeud papillon (si equipe) — SOUS le visage
            if hasEquipped("noeud") {
                bowTieAccessory
            }

            // 8. Chapeau (si equipe) — AU-DESSUS de tout
            equippedHat

            // 9. Ailes (si equipees) — DE CHAQUE COTE
            if hasEquipped("ailes") {
                wingsAccessory
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Body

    private var mochiBody: some View {
        Ellipse()
            .fill(bodyGradient)
            .frame(width: size * 0.85, height: size * 0.75)
            .overlay(
                Ellipse()
                    .stroke(bodyStrokeColor, lineWidth: size * 0.012)
                    .frame(width: size * 0.85, height: size * 0.75)
            )
            .shadow(color: bodyColor.opacity(0.4), radius: 8, y: 4)
            .overlay(
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.5), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size * 0.45, height: size * 0.3)
                    .offset(x: -size * 0.1, y: -size * 0.1)
            )
    }

    private var bodyStrokeColor: Color {
        switch color {
        case .white: return Color(red: 0.82, green: 0.80, blue: 0.77)
        case .pink: return Color(red: 0.9, green: 0.6, blue: 0.68)
        case .teal: return Color(red: 0.40, green: 0.68, blue: 0.63)
        case .matcha: return Color(red: 0.55, green: 0.72, blue: 0.53)
        case .skyBlue: return Color(red: 0.55, green: 0.7, blue: 0.9)
        case .golden: return Color(red: 0.9, green: 0.75, blue: 0.35)
        }
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
        case .white: return Color(red: 0.95, green: 0.92, blue: 0.86)
        case .pink: return Color(red: 1.0, green: 0.8, blue: 0.85)
        case .teal: return Color(red: 0.55, green: 0.83, blue: 0.78)
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

    private var faceColor: Color {
        Color(red: 0.2, green: 0.15, blue: 0.12)
    }

    private var mochiEye: some View {
        Ellipse()
            .fill(faceColor)
            .frame(width: size * 0.09, height: size * 0.11)
    }

    private var happyEye: some View {
        HalfCircleShape()
            .stroke(faceColor, lineWidth: size * 0.03)
            .frame(width: size * 0.1, height: size * 0.06)
    }

    private var starEye: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.1))
            .foregroundStyle(.yellow)
    }

    private func determinedEye(left: Bool) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(faceColor)
                .frame(width: size * 0.09, height: size * 0.02)
                .rotationEffect(.degrees(left ? -10 : 10))
            Ellipse()
                .fill(faceColor)
                .frame(width: size * 0.06, height: size * 0.07)
        }
    }

    private var closedEye: some View {
        HalfCircleShape()
            .rotation(.degrees(180))
            .stroke(faceColor, lineWidth: size * 0.025)
            .frame(width: size * 0.08, height: size * 0.04)
    }

    private var worriedEye: some View {
        Ellipse()
            .fill(faceColor)
            .frame(width: size * 0.08, height: size * 0.1)
    }

    private var sadEye: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(faceColor)
                .frame(width: size * 0.09, height: size * 0.015)
                .rotationEffect(.degrees(10))
            Ellipse()
                .fill(faceColor)
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
                    .fill(faceColor)
                    .frame(width: size * 0.06, height: size * 0.05)
            } else if flat {
                Rectangle()
                    .fill(faceColor)
                    .frame(width: size * (wide ? 0.1 : 0.06), height: size * 0.015)
            } else if wavy {
                WavyLineShape()
                    .stroke(faceColor, lineWidth: size * 0.02)
                    .frame(width: size * 0.08, height: size * 0.03)
            } else if sad {
                HalfCircleShape()
                    .rotation(.degrees(180))
                    .stroke(faceColor, lineWidth: size * 0.02)
                    .frame(width: size * 0.07, height: size * 0.03)
            } else {
                HalfCircleShape()
                    .stroke(faceColor, lineWidth: size * 0.02)
                    .frame(width: size * (wide ? 0.1 : 0.07), height: size * 0.03)
            }
        }
    }

    // MARK: - Equipped Items Helpers

    private func hasEquipped(_ keyword: String) -> Bool {
        equippedItems.contains { $0.name.lowercased().contains(keyword) }
    }

    // MARK: - Hat

    @ViewBuilder
    private var equippedHat: some View {
        if let hat = equippedItems.first(where: { $0.category == .hat }) {
            let name = hat.name.lowercased()
            if name.contains("beret") {
                beretHat
            } else if name.contains("couronne") {
                crownHat
            } else if name.contains("casquette") {
                capHat
            } else if name.contains("sorcier") {
                wizardHat
            } else if name.contains("ninja") || name.contains("bandeau") {
                ninjaBand
            }
        }
    }

    // MARK: - Beret

    private var beretHat: some View {
        ZStack {
            // Corps du beret
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.15, blue: 0.18),
                            Color(red: 0.55, green: 0.1, blue: 0.13),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.4, height: size * 0.15)
                .rotationEffect(.degrees(-8))
            // Tige sur le dessus
            Circle()
                .fill(Color(red: 0.55, green: 0.1, blue: 0.13))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(y: -size * 0.07)
        }
        .offset(y: -size * 0.33)
    }

    // MARK: - Couronne

    private var crownHat: some View {
        ZStack {
            // Base de la couronne
            CrownShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 0.85, green: 0.65, blue: 0.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.35, height: size * 0.18)
            // Joyaux sur les pointes
            HStack(spacing: size * 0.06) {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: size * 0.03)
                    .offset(y: -size * 0.02)
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: size * 0.03)
                    .offset(y: -size * 0.06)
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: size * 0.03)
                    .offset(y: -size * 0.02)
            }
        }
        .offset(y: -size * 0.35)
    }

    // MARK: - Casquette

    private var capHat: some View {
        ZStack {
            // Dome de la casquette
            HalfCircleShape()
                .rotation(.degrees(180))
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.5, blue: 0.8),
                            Color(red: 0.2, green: 0.38, blue: 0.65),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.35, height: size * 0.14)
            // Visiere
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.4, blue: 0.68),
                            Color(red: 0.18, green: 0.32, blue: 0.55),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.22, height: size * 0.06)
                .offset(x: size * 0.15, y: size * 0.04)
        }
        .offset(y: -size * 0.32)
    }

    // MARK: - Chapeau Sorcier

    private var wizardHat: some View {
        ZStack {
            // Cone du chapeau
            WizardHatShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.15, blue: 0.5),
                            Color(red: 0.45, green: 0.2, blue: 0.7),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.3, height: size * 0.35)
            // Bord du chapeau
            Ellipse()
                .fill(Color(red: 0.35, green: 0.18, blue: 0.55))
                .frame(width: size * 0.4, height: size * 0.06)
                .offset(y: size * 0.14)
            // Etoiles decoratives
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.04))
                .foregroundStyle(Color.yellow.opacity(0.9))
                .offset(x: -size * 0.04, y: -size * 0.02)
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.03))
                .foregroundStyle(Color.yellow.opacity(0.7))
                .offset(x: size * 0.06, y: size * 0.06)
        }
        .rotationEffect(.degrees(-5))
        .offset(y: -size * 0.42)
    }

    // MARK: - Bandeau Ninja (style Naruto)

    private var ninjaBand: some View {
        let clothColor = Color(red: 0.15, green: 0.2, blue: 0.45)
        let clothColor2 = Color(red: 0.1, green: 0.15, blue: 0.35)
        let metalLight = Color(red: 0.78, green: 0.78, blue: 0.82)
        let metalDark = Color(red: 0.5, green: 0.5, blue: 0.55)

        return ZStack {
            // Bandeau tissu principal (bleu fonce)
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(LinearGradient(colors: [clothColor, clothColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.07)

            // Bandes qui flottent a droite (2 longues bandes)
            RoundedRectangle(cornerRadius: size * 0.008)
                .fill(LinearGradient(colors: [clothColor, clothColor2.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                .frame(width: size * 0.2, height: size * 0.04)
                .rotationEffect(.degrees(25))
                .offset(x: size * 0.35, y: size * 0.06)

            RoundedRectangle(cornerRadius: size * 0.008)
                .fill(LinearGradient(colors: [clothColor, clothColor2.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                .frame(width: size * 0.17, height: size * 0.035)
                .rotationEffect(.degrees(35))
                .offset(x: size * 0.32, y: size * 0.1)

            // Plaque metallique au centre (plus grande, style Naruto)
            RoundedRectangle(cornerRadius: size * 0.012)
                .fill(LinearGradient(colors: [metalLight, metalDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.1, height: size * 0.065)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.012)
                        .stroke(metalDark, lineWidth: size * 0.005)
                )

            // Symbole sur la plaque (spirale simplifiee)
            Circle()
                .stroke(metalDark, lineWidth: size * 0.006)
                .frame(width: size * 0.035, height: size * 0.035)
            Circle()
                .fill(metalDark)
                .frame(width: size * 0.012, height: size * 0.012)

            // Vis de la plaque
            Circle()
                .fill(metalDark.opacity(0.6))
                .frame(width: size * 0.008, height: size * 0.008)
                .offset(x: -size * 0.035, y: 0)
            Circle()
                .fill(metalDark.opacity(0.6))
                .frame(width: size * 0.008, height: size * 0.008)
                .offset(x: size * 0.035, y: 0)
        }
        .offset(y: -size * 0.2)
    }

    // MARK: - Lunettes de soleil

    private var glassesAccessory: some View {
        let frameColor = Color(red: 0.1, green: 0.1, blue: 0.12)
        let lensColor = LinearGradient(
            colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.25, green: 0.2, blue: 0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let lensW = size * 0.16
        let lensH = size * 0.11
        let eyeSpacing = size * 0.075

        return ZStack {
            // Verre gauche - opaque fonce
            RoundedRectangle(cornerRadius: lensH * 0.45)
                .fill(lensColor)
                .frame(width: lensW, height: lensH)
                .overlay(
                    RoundedRectangle(cornerRadius: lensH * 0.45)
                        .stroke(frameColor, lineWidth: size * 0.01)
                )
                .overlay(
                    // Reflet
                    Ellipse()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: lensW * 0.4, height: lensH * 0.3)
                        .offset(x: -lensW * 0.15, y: -lensH * 0.15)
                )
                .offset(x: -eyeSpacing)
            // Verre droit
            RoundedRectangle(cornerRadius: lensH * 0.45)
                .fill(lensColor)
                .frame(width: lensW, height: lensH)
                .overlay(
                    RoundedRectangle(cornerRadius: lensH * 0.45)
                        .stroke(frameColor, lineWidth: size * 0.01)
                )
                .overlay(
                    Ellipse()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: lensW * 0.4, height: lensH * 0.3)
                        .offset(x: -lensW * 0.15, y: -lensH * 0.15)
                )
                .offset(x: eyeSpacing)
            // Pont central
            RoundedRectangle(cornerRadius: size * 0.005)
                .fill(frameColor)
                .frame(width: eyeSpacing * 0.35, height: size * 0.015)
        }
        .offset(y: -size * 0.07)
    }

    // MARK: - Echarpe

    private var scarfAccessory: some View {
        let scarfColor1 = Color(red: 0.85, green: 0.2, blue: 0.2)
        let scarfColor2 = Color(red: 0.65, green: 0.12, blue: 0.12)

        return ZStack {
            // Bande principale - enroule autour du bas du Mochi
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: size * 0.65, height: size * 0.08)
                .offset(y: size * 0.18)

            // Rayures decoratives
            HStack(spacing: size * 0.08) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: size * 0.01, height: size * 0.06)
                }
            }
            .offset(y: size * 0.18)

            // Bout gauche qui pend
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.08, height: size * 0.18)
                .rotationEffect(.degrees(-12))
                .offset(x: -size * 0.28, y: size * 0.28)

            // Bout droit plus court
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.07, height: size * 0.12)
                .rotationEffect(.degrees(8))
                .offset(x: -size * 0.2, y: size * 0.32)

            // Franges bout gauche
            HStack(spacing: size * 0.008) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: size * 0.003)
                        .fill(scarfColor2)
                        .frame(width: size * 0.012, height: size * 0.025)
                }
            }
            .rotationEffect(.degrees(-12))
            .offset(x: -size * 0.28, y: size * 0.38)
        }
    }

    // MARK: - Noeud Papillon

    private var bowTieAccessory: some View {
        let bowColor1 = Color(red: 0.85, green: 0.15, blue: 0.2)
        let bowColor2 = Color(red: 0.65, green: 0.08, blue: 0.12)
        let wingW = size * 0.13
        let wingH = size * 0.09

        return ZStack {
            // Aile gauche
            BowTieWingShape()
                .fill(LinearGradient(colors: [bowColor1, bowColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: wingW, height: wingH)
                .offset(x: -wingW * 0.45)
            // Aile droite (miroir)
            BowTieWingShape()
                .fill(LinearGradient(colors: [bowColor1, bowColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: wingW, height: wingH)
                .scaleEffect(x: -1, y: 1)
                .offset(x: wingW * 0.45)
            // Noeud central
            Circle()
                .fill(bowColor2)
                .frame(width: size * 0.04, height: size * 0.04)
        }
        .offset(y: size * 0.16)
    }

    // MARK: - Cape

    private var capeAccessory: some View {
        CapeShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.15, blue: 0.6),
                        Color(red: 0.25, green: 0.1, blue: 0.45),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.95, height: size * 0.8)
            .overlay(
                CapeShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.2, blue: 0.8).opacity(0.3),
                                .clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.95, height: size * 0.8)
            )
            .offset(y: size * 0.08)
    }

    // MARK: - Ailes

    private var wingsAccessory: some View {
        HStack(spacing: size * 0.55) {
            // Aile gauche
            WingShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color(red: 0.85, green: 0.9, blue: 1.0).opacity(0.4),
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: size * 0.2, height: size * 0.3)
                .scaleEffect(x: -1, y: 1)
            // Aile droite
            WingShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color(red: 0.85, green: 0.9, blue: 1.0).opacity(0.4),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.2, height: size * 0.3)
        }
        .offset(y: -size * 0.02)
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

// MARK: - Crown Shape

struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Base
        path.move(to: CGPoint(x: 0, y: h))
        // Montee vers la premiere pointe
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.3))
        // Creux entre pointes
        path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.55))
        // Pointe centrale (la plus haute)
        path.addLine(to: CGPoint(x: w * 0.5, y: 0))
        // Creux
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.55))
        // Derniere pointe
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.3))
        // Retour a la base
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Wizard Hat Shape

struct WizardHatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Pointe du chapeau (legerement decalee pour effet penche)
        path.move(to: CGPoint(x: w * 0.45, y: 0))
        // Cote gauche avec courbe
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h),
            control: CGPoint(x: w * 0.15, y: h * 0.5)
        )
        // Base
        path.addLine(to: CGPoint(x: w, y: h))
        // Cote droit avec courbe
        path.addQuadCurve(
            to: CGPoint(x: w * 0.45, y: 0),
            control: CGPoint(x: w * 0.8, y: h * 0.5)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Bow Tie Wing Shape

struct BowTieWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Commence au centre (noeud)
        path.move(to: CGPoint(x: 0, y: h * 0.4))
        // Courbe vers le haut puis l'extremite
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w * 0.5, y: -h * 0.2)
        )
        // Extremite vers le bas
        path.addQuadCurve(
            to: CGPoint(x: w, y: h),
            control: CGPoint(x: w * 1.1, y: h * 0.5)
        )
        // Retour au centre par le bas
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.6),
            control: CGPoint(x: w * 0.5, y: h * 1.2)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Cape Shape

struct CapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Haut de la cape (attache aux epaules)
        path.move(to: CGPoint(x: w * 0.2, y: 0))
        path.addLine(to: CGPoint(x: w * 0.8, y: 0))
        // Cote droit qui descend avec courbe
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.9),
            control: CGPoint(x: w * 1.0, y: h * 0.4)
        )
        // Bord inferieur ondule
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.7, y: h * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.9),
            control: CGPoint(x: w * 0.3, y: h * 0.8)
        )
        // Cote gauche qui remonte
        path.addQuadCurve(
            to: CGPoint(x: w * 0.2, y: 0),
            control: CGPoint(x: 0, y: h * 0.4)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Wing Shape

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Base de l'aile (attachee au corps)
        path.move(to: CGPoint(x: 0, y: h * 0.3))
        // Partie superieure de l'aile
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.1),
            control: CGPoint(x: w * 0.3, y: -h * 0.1)
        )
        // Pointe de l'aile
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control: CGPoint(x: w * 1.0, y: h * 0.05)
        )
        // Bord inferieur avec ondulations (3 plumes)
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.55),
            control: CGPoint(x: w * 0.9, y: h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.4, y: h * 0.7),
            control: CGPoint(x: w * 0.6, y: h * 0.7)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.7),
            control: CGPoint(x: w * 0.2, y: h * 0.8)
        )
        path.closeSubpath()
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
