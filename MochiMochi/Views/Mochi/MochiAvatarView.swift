import SwiftUI

struct MochiAvatarView: View {
    let emotion: MochiEmotion
    let color: MochiColor
    let equippedItems: [ShopItem]
    var size: CGFloat = 160

    // MARK: - Animation State

    @State private var isBlinking = false
    @State private var blinkTimer: Timer?
    @State private var breathPhase: CGFloat = 0
    @State private var pupilOffset: CGPoint = .zero
    @State private var pupilTimer: Timer?
    @State private var thinkingDotsAnimate = false
    @State private var thinkingIconIndex: Int = 0
    @State private var thinkingIconTimer: Timer?
    @State private var listeningPulse = false
    @State private var writingDotsIndex = 0
    @State private var writingTimer: Timer?

    private let thinkingIcons = ["magnifyingglass", "book.fill"]

    // MARK: - Body Dimensions

    private var bodyW: CGFloat { size * 0.77 }
    private var bodyH: CGFloat { size * 0.56 }
    private var outlineW: CGFloat { size * 0.038 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Soft radial background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [bodyColor.opacity(color.isDark ? 0.08 : 0.05), .clear],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)

            // Cape (behind body)
            if hasEquipped("cape") { capeAccessory }

            // Body with breathing
            mochiBody
                .scaleEffect(
                    x: 1.0 + breathPhase * 0.015,
                    y: 1.0 + breathPhase * 0.025,
                    anchor: .bottom
                )

            // Scarf
            if hasEquipped("echarpe") { scarfAccessory }

            // Face
            mochiFace
                .offset(
                    x: pupilOffset.x * size * 0.004,
                    y: size * 0.02 + pupilOffset.y * size * 0.002
                )

            // Cheek blush
            cheekBlush
                .offset(y: size * 0.06)

            // Glasses
            if hasEquipped("lunettes") { glassesAccessory }

            // Bow tie
            if hasEquipped("noeud") { bowTieAccessory }

            // Hat
            equippedHat

            // Wings
            if hasEquipped("ailes") { wingsAccessory }

            // Emotion particles
            emotionParticles
        }
        .frame(width: size, height: size)
        .onAppear { startAllAnimations() }
        .onDisappear { stopAllAnimations() }
    }

    // MARK: - Mochi Body (CSS-Inspired Daifuku)

    private var mochiBody: some View {
        let bShape = UnevenRoundedRectangle(
            topLeadingRadius: bodyH * 0.67,
            bottomLeadingRadius: bodyH * 0.18,
            bottomTrailingRadius: bodyH * 0.18,
            topTrailingRadius: bodyH * 0.67
        )

        return ZStack {
            // Drop shadow
            bShape
                .fill(outlineColor.opacity(0.25))
                .frame(width: bodyW, height: bodyH)
                .offset(y: size * 0.015)
                .blur(radius: size * 0.025)

            // Body content (fill + highlight) — clipped to body shape
            ZStack {
                // Base fill
                bShape.fill(bodyGradient)

                // Highlight circle (3D dome effect)
                Circle()
                    .fill(highlightColor)
                    .frame(width: max(bodyW, bodyH))
                    .offset(x: bodyW * 0.19)
            }
            .frame(width: bodyW, height: bodyH)
            .clipShape(bShape)

            // Thick outline
            bShape
                .stroke(outlineColor, lineWidth: outlineW)
                .frame(width: bodyW, height: bodyH)

            // Small specular dot
            Circle()
                .fill(.white.opacity(color.isDark ? 0.1 : 0.22))
                .frame(width: size * 0.04, height: size * 0.03)
                .offset(x: -bodyW * 0.22, y: -bodyH * 0.28)
                .blur(radius: size * 0.004)

            // Leaves on top
            leavesView
                .offset(y: -bodyH * 0.58)
        }
    }

    // MARK: - Bite Marks (3-Layer Cross-Section)

    private var biteMarksView: some View {
        let baseSize = bodyW * 0.484
        let midSize = bodyW * 0.383
        let topSize = bodyW * 0.302

        // Two bite centers (relative to body center)
        let bite1X = bodyW * 0.34
        let bite1Y = -bodyH * 0.28
        let bite2X = bodyW * 0.42
        let bite2Y = bodyH * 0.06

        return ZStack {
            // Base layer (dark, outline color)
            Circle().fill(outlineColor)
                .frame(width: baseSize, height: baseSize)
                .offset(x: bite1X, y: bite1Y)
            Circle().fill(outlineColor)
                .frame(width: baseSize, height: baseSize)
                .offset(x: bite2X, y: bite2Y)

            // Middle layer (highlight color)
            Circle().fill(highlightColor)
                .frame(width: midSize, height: midSize)
                .offset(x: bite1X, y: bite1Y)
            Circle().fill(highlightColor)
                .frame(width: midSize, height: midSize)
                .offset(x: bite2X, y: bite2Y)

            // Top layer (very light)
            Circle().fill(biteTopColor)
                .frame(width: topSize, height: topSize)
                .offset(x: bite1X, y: bite1Y)
            Circle().fill(biteTopColor)
                .frame(width: topSize, height: topSize)
                .offset(x: bite2X, y: bite2Y)
        }
        .rotationEffect(.degrees(-10))
        .offset(x: size * 0.015, y: -size * 0.01)
    }

    // MARK: - Leaves

    private var leavesView: some View {
        let leafW = bodyW * 0.18
        let leafH = bodyW * 0.38
        let leafOuterColor = Color(red: 0.49, green: 0.65, blue: 0.45)
        let leafInnerColor = Color(red: 0.62, green: 0.82, blue: 0.57)
        let stemColor = Color(red: 0.38, green: 0.52, blue: 0.34)
        let leafStroke = outlineW * 0.85

        return ZStack {
            // Leaf 2 (behind, tilted left)
            singleLeaf(w: leafW, h: leafH, outer: leafOuterColor, inner: leafInnerColor, stem: stemColor, stroke: leafStroke)
                .rotationEffect(.degrees(-55), anchor: .bottom)
                .offset(x: 0, y: -size * 0.03)

            // Leaf 1 (front, tilted right)
            singleLeaf(w: leafW, h: leafH, outer: leafOuterColor, inner: leafInnerColor, stem: stemColor, stroke: leafStroke)
                .rotationEffect(.degrees(45), anchor: .bottom)
                .offset(x: 0, y: -size * 0.03)

        }
    }

    private func singleLeaf(w: CGFloat, h: CGFloat, outer: Color, inner: Color, stem: Color, stroke strokeW: CGFloat) -> some View {
        ZStack {
            VerticalLeafShape()
                .fill(outer)
            VerticalLeafShape()
                .fill(inner)
                .scaleEffect(x: 0.50, y: 0.45)
                .offset(x: w * 0.06, y: -h * 0.08)
            // Center vein
            Path { path in
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.15))
                path.addQuadCurve(
                    to: CGPoint(x: w * 0.5, y: h * 0.85),
                    control: CGPoint(x: w * 0.75, y: h * 0.5)
                )
            }
            .stroke(stem, lineWidth: w * 0.08)
            .opacity(0.5)
        }
        .frame(width: w, height: h)
    }

    // MARK: - Cheek Blush

    private var cheekBlush: some View {
        let blushOpacity: Double = {
            switch emotion {
            case .happy, .excited, .proud: return 0.25
            case .worried, .sad: return 0.08
            case .sleeping: return 0.2
            default: return 0.15
            }
        }()

        return HStack(spacing: size * 0.2) {
            Ellipse()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.6).opacity(blushOpacity))
                .frame(width: size * 0.1, height: size * 0.055)
                .blur(radius: size * 0.012)

            Ellipse()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.6).opacity(blushOpacity))
                .frame(width: size * 0.1, height: size * 0.055)
                .blur(radius: size * 0.012)
        }
        .animation(.easeInOut(duration: 0.5), value: emotion)
    }

    // MARK: - Face

    @ViewBuilder
    private var mochiFace: some View {
        switch emotion {
        case .idle: idleFace
        case .happy: happyFace
        case .excited: excitedFace
        case .focused: focusedFace
        case .sleeping: sleepingFace
        case .worried: worriedFace
        case .sad: sadFace
        case .proud: proudFace
        case .thinking: thinkingFace
        case .listening: listeningFace
        case .writing: writingFace
        }
    }

    // MARK: - Idle Face

    private var idleFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                kawaiiEye
                kawaiiEye
            }
            gentleSmileMouth
        }
    }

    // MARK: - Happy Face

    private var happyFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                kawaiiEye
                kawaiiEye
            }
            wideSmileMouth
        }
    }

    // MARK: - Excited Face

    private var excitedFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                starEye
                starEye
            }
            openMouth
        }
    }

    // MARK: - Focused Face

    private var focusedFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                determinedEye(left: true)
                determinedEye(left: false)
            }
            flatMouth
        }
    }

    // MARK: - Sleeping Face

    private var sleepingFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                closedEye
                closedEye
            }
            .overlay(
                Text("Zzz")
                    .font(.system(size: size * 0.09, weight: .bold, design: .rounded))
                    .foregroundStyle(faceColor.opacity(0.45))
                    .offset(x: size * 0.24, y: -size * 0.1)
            )
            flatMouth
        }
    }

    // MARK: - Worried Face

    private var worriedFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                worriedEye
                worriedEye
            }
            wavyMouth
        }
        .overlay(
            SweatDropShape()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.5), Color.cyan.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.04, height: size * 0.06)
                .offset(x: size * 0.22, y: -size * 0.06)
        )
    }

    // MARK: - Sad Face

    private var sadFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                sadEye
                sadEye
            }
            sadMouth
        }
        .overlay(
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.55), Color.cyan.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.025, height: size * 0.05)
                .offset(x: -size * 0.06, y: size * 0.03)
        )
    }

    // MARK: - Proud Face

    private var proudFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                kawaiiEye
                kawaiiEye
            }
            wideSmileMouth
        }
    }

    // MARK: - Thinking Face

    private var thinkingFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                kawaiiEye
                kawaiiEye
                    .offset(y: -size * 0.02)
            }
            flatMouth
        }
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: size * 0.035)
                    .offset(x: size * 0.13, y: -size * 0.06)

                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.055)
                    .offset(x: size * 0.18, y: -size * 0.1)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                        .frame(width: size * 0.2, height: size * 0.2)

                    Image(systemName: thinkingIcons[thinkingIconIndex % thinkingIcons.count])
                        .font(.system(size: size * 0.08))
                        .foregroundStyle(MochiTheme.primary.opacity(0.7))
                        .id(thinkingIconIndex)
                        .transition(.opacity)
                }
                .offset(x: size * 0.27, y: -size * 0.2)
            }
            .opacity(thinkingDotsAnimate ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.3), value: thinkingDotsAnimate)
        )
        .onAppear {
            thinkingDotsAnimate = true
            startThinkingIconCycle()
        }
        .onDisappear {
            thinkingDotsAnimate = false
            thinkingIconTimer?.invalidate()
            thinkingIconTimer = nil
        }
    }

    // MARK: - Listening Face

    private var listeningFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                kawaiiEye
                kawaiiEye
            }
            Circle()
                .fill(faceColor)
                .frame(width: size * 0.045, height: size * 0.045)
        }
        .overlay(
            HStack(spacing: size * 0.012) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: size * 0.005)
                        .fill(MochiTheme.primary.opacity(0.6))
                        .frame(
                            width: size * 0.015,
                            height: listeningPulse
                                ? size * CGFloat([0.06, 0.1, 0.08, 0.05][index])
                                : size * CGFloat([0.03, 0.05, 0.04, 0.03][index])
                        )
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: listeningPulse
                        )
                }
            }
            .offset(x: size * 0.28, y: -size * 0.02)
        )
        .overlay(
            Image(systemName: "mic.fill")
                .font(.system(size: size * 0.07))
                .foregroundStyle(MochiTheme.primary.opacity(0.5))
                .offset(x: -size * 0.28, y: -size * 0.05)
        )
        .onAppear { listeningPulse = true }
        .onDisappear { listeningPulse = false }
    }

    // MARK: - Writing Face

    private var writingFace: some View {
        VStack(spacing: size * 0.035) {
            HStack(spacing: size * 0.14) {
                determinedEye(left: true)
                determinedEye(left: false)
            }
            flatMouth
        }
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: size * 0.03)
                    .offset(x: size * 0.13, y: -size * 0.05)

                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.045)
                    .offset(x: size * 0.18, y: -size * 0.09)

                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.04)
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                        .frame(width: size * 0.22, height: size * 0.15)

                    HStack(spacing: size * 0.02) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(MochiTheme.primary.opacity(writingDotsIndex == index ? 1.0 : 0.3))
                                .frame(width: size * 0.025, height: size * 0.025)
                                .animation(.easeInOut(duration: 0.2), value: writingDotsIndex)
                        }
                    }
                }
                .offset(x: size * 0.27, y: -size * 0.18)
            }
        )
        .onAppear { startWritingDots() }
        .onDisappear {
            writingTimer?.invalidate()
            writingTimer = nil
        }
    }

    // MARK: - Eye Components

    private var faceColor: Color {
        color.isDark
            ? Color(red: 0.92, green: 0.9, blue: 0.85)
            : Color(red: 0.2, green: 0.15, blue: 0.12)
    }

    private var kawaiiEye: some View {
        ZStack {
            Ellipse()
                .fill(faceColor)
                .frame(width: size * 0.095, height: isBlinking ? size * 0.012 : size * 0.115)

            if !isBlinking {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.032, height: size * 0.032)
                    .offset(x: size * 0.012, y: -size * 0.022)

                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: size * 0.016, height: size * 0.016)
                    .offset(x: -size * 0.015, y: size * 0.016)
            }
        }
    }

    private var happyArcEye: some View {
        HalfCircleShape()
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.028, lineCap: .round))
            .frame(width: size * 0.1, height: size * 0.055)
    }

    private var starEye: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.1))
            .foregroundStyle(.yellow)
            .shadow(color: .yellow.opacity(0.4), radius: size * 0.02)
    }

    private func determinedEye(left: Bool) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: size * 0.005)
                .fill(faceColor)
                .frame(width: size * 0.09, height: size * 0.018)
                .rotationEffect(.degrees(left ? -10 : 10))
            ZStack {
                Ellipse()
                    .fill(faceColor)
                    .frame(width: size * 0.06, height: size * 0.065)
                if !isBlinking {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.02, height: size * 0.02)
                        .offset(x: size * 0.008, y: -size * 0.01)
                }
            }
        }
    }

    private var closedEye: some View {
        HalfCircleShape()
            .rotation(.degrees(180))
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round))
            .frame(width: size * 0.08, height: size * 0.04)
    }

    private var worriedEye: some View {
        ZStack {
            Ellipse()
                .fill(faceColor)
                .frame(width: size * 0.08, height: isBlinking ? size * 0.012 : size * 0.095)
            if !isBlinking {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.025, height: size * 0.025)
                    .offset(x: size * 0.01, y: -size * 0.015)
            }
        }
    }

    private var sadEye: some View {
        VStack(spacing: 1) {
            RoundedRectangle(cornerRadius: size * 0.005)
                .fill(faceColor)
                .frame(width: size * 0.09, height: size * 0.014)
                .rotationEffect(.degrees(10))
            ZStack {
                Ellipse()
                    .fill(faceColor)
                    .frame(width: size * 0.055, height: size * 0.065)
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: size * 0.018, height: size * 0.018)
                    .offset(x: size * 0.008, y: -size * 0.01)
            }
        }
    }

    // MARK: - Mouth Components

    private var gentleSmileMouth: some View {
        HalfCircleShape()
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.018, lineCap: .round))
            .frame(width: size * 0.065, height: size * 0.025)
    }

    private var wideSmileMouth: some View {
        HalfCircleShape()
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round))
            .frame(width: size * 0.1, height: size * 0.03)
    }

    private var openMouth: some View {
        Ellipse()
            .fill(faceColor)
            .frame(width: size * 0.055, height: size * 0.045)
    }

    private var flatMouth: some View {
        RoundedRectangle(cornerRadius: size * 0.005)
            .fill(faceColor)
            .frame(width: size * 0.055, height: size * 0.014)
    }

    private var wavyMouth: some View {
        WavyLineShape()
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.018, lineCap: .round))
            .frame(width: size * 0.08, height: size * 0.025)
    }

    private var sadMouth: some View {
        HalfCircleShape()
            .rotation(.degrees(180))
            .stroke(faceColor, style: StrokeStyle(lineWidth: size * 0.018, lineCap: .round))
            .frame(width: size * 0.065, height: size * 0.025)
    }

    // MARK: - Emotion Particles

    @ViewBuilder
    private var emotionParticles: some View {
        switch emotion {
        case .excited:
            excitedSparkles
        case .proud:
            proudShimmer
        default:
            EmptyView()
        }
    }

    private var excitedSparkles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    let angle = t * 0.6 + Double(i) * (2.0 * .pi / 5.0)
                    let r = size * 0.46
                    let x = cos(angle) * r
                    let y = sin(angle) * r * 0.5
                    let op = 0.35 + 0.3 * sin(t * 2.0 + Double(i) * 1.3)
                    let sc = 0.6 + 0.35 * sin(t * 1.5 + Double(i))

                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.05, weight: .bold))
                        .foregroundStyle(.yellow)
                        .offset(x: x, y: y - size * 0.04)
                        .opacity(op)
                        .scaleEffect(sc)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var proudShimmer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let angle = t * 0.4 + Double(i) * (.pi / 2.0)
                    let r = size * 0.48
                    let x = cos(angle) * r
                    let y = sin(angle) * r * 0.45
                    let op = 0.2 + 0.25 * sin(t * 1.5 + Double(i) * 1.5)

                    Image(systemName: "star.fill")
                        .font(.system(size: size * 0.035))
                        .foregroundStyle(Color.yellow.opacity(op))
                        .offset(x: x, y: y - size * 0.04)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animation Lifecycle

    private func startAllAnimations() {
        startBlinkTimer()
        startBreathing()
        startPupilDrift()
    }

    private func stopAllAnimations() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        pupilTimer?.invalidate()
        pupilTimer = nil
        thinkingIconTimer?.invalidate()
        thinkingIconTimer = nil
        writingTimer?.invalidate()
        writingTimer = nil
    }

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breathPhase = 1.0
        }
    }

    private func startPupilDrift() {
        schedulePupilMove()
    }

    private func schedulePupilMove() {
        let interval = Double.random(in: 2.5...5.0)
        pupilTimer?.invalidate()
        pupilTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                let newX = CGFloat.random(in: -1.5...1.5)
                let newY = CGFloat.random(in: -0.8...0.8)
                withAnimation(.easeInOut(duration: 0.6)) {
                    pupilOffset = CGPoint(x: newX, y: newY)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.2...2.5)) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        pupilOffset = .zero
                    }
                    schedulePupilMove()
                }
            }
        }
    }

    private func startBlinkTimer() {
        blinkTimer?.invalidate()
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let interval = Double.random(in: 2.5...5.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.easeIn(duration: 0.07)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.09)) {
                        isBlinking = false
                    }
                    scheduleNextBlink()
                }
            }
        }
    }

    private func startThinkingIconCycle() {
        thinkingIconTimer?.invalidate()
        thinkingIconTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.4)) {
                    thinkingIconIndex = (thinkingIconIndex + 1) % thinkingIcons.count
                }
            }
        }
    }

    private func startWritingDots() {
        writingTimer?.invalidate()
        writingTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            Task { @MainActor in
                writingDotsIndex = (writingDotsIndex + 1) % 3
            }
        }
    }

    // MARK: - Equipped Items Helpers

    private func hasEquipped(_ keyword: String) -> Bool {
        equippedItems.contains { $0.name.lowercased().contains(keyword) }
    }

    // MARK: - Color Properties

    private var outlineColor: Color { bodyStrokeColor }

    private var highlightColor: Color {
        lightenColor(bodyColor, by: 0.35)
    }

    private var biteTopColor: Color {
        lightenColor(bodyColor, by: 0.7)
    }

    private func lightenColor(_ c: Color, by amount: CGFloat) -> Color {
        guard let srgb = NSColor(c).usingColorSpace(.sRGB) else { return c }
        return Color(
            red: min(1, srgb.redComponent + (1 - srgb.redComponent) * amount),
            green: min(1, srgb.greenComponent + (1 - srgb.greenComponent) * amount),
            blue: min(1, srgb.blueComponent + (1 - srgb.blueComponent) * amount)
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
        case .grey: return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .black: return Color(red: 0.25, green: 0.25, blue: 0.25)
        case .nightBlue: return Color(red: 0.1, green: 0.12, blue: 0.35)
        case .violet: return Color(red: 0.55, green: 0.3, blue: 0.7)
        case .pride: return Color(red: 0.85, green: 0.4, blue: 0.4)
        }
    }

    private var bodyGradient: LinearGradient {
        if color == .pride {
            return LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.3, blue: 0.3),
                    Color(red: 0.95, green: 0.6, blue: 0.2),
                    Color(red: 0.95, green: 0.9, blue: 0.3),
                    Color(red: 0.3, green: 0.8, blue: 0.4),
                    Color(red: 0.3, green: 0.5, blue: 0.9),
                    Color(red: 0.6, green: 0.3, blue: 0.8),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [bodyColor.opacity(0.92), bodyColor],
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
        case .grey: return Color(red: 0.72, green: 0.72, blue: 0.72)
        case .black: return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .nightBlue: return Color(red: 0.12, green: 0.15, blue: 0.35)
        case .violet: return Color(red: 0.7, green: 0.45, blue: 0.85)
        case .pride: return Color(red: 0.9, green: 0.5, blue: 0.5)
        }
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

    private var beretHat: some View {
        ZStack {
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
            Circle()
                .fill(Color(red: 0.55, green: 0.1, blue: 0.13))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(y: -size * 0.07)
        }
        .offset(y: -size * 0.3)
    }

    private var crownHat: some View {
        ZStack {
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
            HStack(spacing: size * 0.06) {
                Circle().fill(Color.red.opacity(0.8)).frame(width: size * 0.03)
                    .offset(y: -size * 0.02)
                Circle().fill(Color.blue.opacity(0.8)).frame(width: size * 0.03)
                    .offset(y: -size * 0.06)
                Circle().fill(Color.red.opacity(0.8)).frame(width: size * 0.03)
                    .offset(y: -size * 0.02)
            }
        }
        .offset(y: -size * 0.32)
    }

    private var capHat: some View {
        ZStack {
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
        .offset(y: -size * 0.29)
    }

    private var wizardHat: some View {
        ZStack {
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
            Ellipse()
                .fill(Color(red: 0.35, green: 0.18, blue: 0.55))
                .frame(width: size * 0.4, height: size * 0.06)
                .offset(y: size * 0.14)
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
        .offset(y: -size * 0.39)
    }

    private var ninjaBand: some View {
        let clothColor = Color(red: 0.15, green: 0.2, blue: 0.45)
        let clothColor2 = Color(red: 0.1, green: 0.15, blue: 0.35)
        let metalLight = Color(red: 0.78, green: 0.78, blue: 0.82)
        let metalDark = Color(red: 0.5, green: 0.5, blue: 0.55)

        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(LinearGradient(colors: [clothColor, clothColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.07)

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

            RoundedRectangle(cornerRadius: size * 0.012)
                .fill(LinearGradient(colors: [metalLight, metalDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.1, height: size * 0.065)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.012)
                        .stroke(metalDark, lineWidth: size * 0.005)
                )

            Circle()
                .stroke(metalDark, lineWidth: size * 0.006)
                .frame(width: size * 0.035, height: size * 0.035)
            Circle()
                .fill(metalDark)
                .frame(width: size * 0.012, height: size * 0.012)

            Circle()
                .fill(metalDark.opacity(0.6))
                .frame(width: size * 0.008, height: size * 0.008)
                .offset(x: -size * 0.035, y: 0)
            Circle()
                .fill(metalDark.opacity(0.6))
                .frame(width: size * 0.008, height: size * 0.008)
                .offset(x: size * 0.035, y: 0)
        }
        .offset(y: -size * 0.18)
    }

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
                .offset(x: -eyeSpacing)
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
            RoundedRectangle(cornerRadius: size * 0.005)
                .fill(frameColor)
                .frame(width: eyeSpacing * 0.35, height: size * 0.015)
        }
        .offset(y: -size * 0.06)
    }

    private var scarfAccessory: some View {
        let scarfColor1 = Color(red: 0.85, green: 0.2, blue: 0.2)
        let scarfColor2 = Color(red: 0.65, green: 0.12, blue: 0.12)

        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: size * 0.65, height: size * 0.08)
                .offset(y: size * 0.18)

            HStack(spacing: size * 0.08) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: size * 0.01, height: size * 0.06)
                }
            }
            .offset(y: size * 0.18)

            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.08, height: size * 0.18)
                .rotationEffect(.degrees(-12))
                .offset(x: -size * 0.28, y: size * 0.28)

            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(
                    LinearGradient(colors: [scarfColor1, scarfColor2.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.07, height: size * 0.12)
                .rotationEffect(.degrees(8))
                .offset(x: -size * 0.2, y: size * 0.32)

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

    private var bowTieAccessory: some View {
        let bowColor1 = Color(red: 0.85, green: 0.15, blue: 0.2)
        let bowColor2 = Color(red: 0.65, green: 0.08, blue: 0.12)
        let wingW = size * 0.13
        let wingH = size * 0.09

        return ZStack {
            BowTieWingShape()
                .fill(LinearGradient(colors: [bowColor1, bowColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: wingW, height: wingH)
                .offset(x: -wingW * 0.45)
            BowTieWingShape()
                .fill(LinearGradient(colors: [bowColor1, bowColor2], startPoint: .top, endPoint: .bottom))
                .frame(width: wingW, height: wingH)
                .scaleEffect(x: -1, y: 1)
                .offset(x: wingW * 0.45)
            Circle()
                .fill(bowColor2)
                .frame(width: size * 0.04, height: size * 0.04)
        }
        .offset(y: size * 0.16)
    }

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

    private var wingsAccessory: some View {
        HStack(spacing: size * 0.55) {
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

/// Vertical leaf shape: pointy tip at top-center, rounded base at bottom.
struct VerticalLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        // Start at the tip (top center)
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        // Right curve down to base
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 1.3, y: h * 0.25),
            control2: CGPoint(x: w * 0.95, y: h * 0.85)
        )
        // Left curve back up to tip
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.05, y: h * 0.85),
            control2: CGPoint(x: -w * 0.3, y: h * 0.25)
        )
        path.closeSubpath()
        return path
    }
}

struct SweatDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 1.1, y: h * 0.6)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: -w * 0.1, y: h * 0.6)
        )
        path.closeSubpath()
        return path
    }
}

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

struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.3))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

struct WizardHatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.45, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h),
            control: CGPoint(x: w * 0.15, y: h * 0.5)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.45, y: 0),
            control: CGPoint(x: w * 0.8, y: h * 0.5)
        )
        path.closeSubpath()
        return path
    }
}

struct BowTieWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w * 0.5, y: -h * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: h),
            control: CGPoint(x: w * 1.1, y: h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.6),
            control: CGPoint(x: w * 0.5, y: h * 1.2)
        )
        path.closeSubpath()
        return path
    }
}

struct CapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.2, y: 0))
        path.addLine(to: CGPoint(x: w * 0.8, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.9),
            control: CGPoint(x: w * 1.0, y: h * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.7, y: h * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.9),
            control: CGPoint(x: w * 0.3, y: h * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.2, y: 0),
            control: CGPoint(x: 0, y: h * 0.4)
        )
        path.closeSubpath()
        return path
    }
}

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.1),
            control: CGPoint(x: w * 0.3, y: -h * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control: CGPoint(x: w * 1.0, y: h * 0.05)
        )
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
