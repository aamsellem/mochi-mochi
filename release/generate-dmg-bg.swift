#!/usr/bin/env swift
import Cocoa

let width: CGFloat = 660
let height: CGFloat = 400

// Create bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(width),
    height: Int(height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Flip coordinate system for easier drawing
ctx.translateBy(x: 0, y: height)
ctx.scaleBy(x: 1, y: -1)

// MARK: - Background gradient (warm beige to soft pink)
let bgColors: [CGFloat] = [
    249/255, 245/255, 240/255, 1.0,  // #F9F5F0 beige chaud (top)
    255/255, 208/255, 208/255, 1.0,  // #FFD0D0 rose pâle (bottom)
]
let bgGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: bgColors,
    locations: [0.0, 1.0],
    count: 2
)!
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: width / 2, y: 0),
    end: CGPoint(x: width / 2, y: height),
    options: []
)

// MARK: - Subtle polka dots pattern
ctx.setFillColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.08)
for row in 0..<20 {
    for col in 0..<30 {
        let x = CGFloat(col) * 28 + (row % 2 == 0 ? 0 : 14)
        let y = CGFloat(row) * 28
        ctx.fillEllipse(in: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
    }
}

// MARK: - Helper: Draw mochi body
func drawMochi(ctx: CGContext, cx: CGFloat, cy: CGFloat, size: CGFloat, alpha: CGFloat = 1.0) {
    let rx = size * 0.5
    let ry = size * 0.42

    // Shadow
    ctx.saveGState()
    ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.06 * alpha)
    ctx.fillEllipse(in: CGRect(
        x: cx - rx * 0.7, y: cy + ry * 0.75,
        width: rx * 1.4, height: ry * 0.3
    ))
    ctx.restoreGState()

    // Body
    let bodyPath = CGMutablePath()
    bodyPath.move(to: CGPoint(x: cx - rx, y: cy))
    bodyPath.addCurve(
        to: CGPoint(x: cx + rx, y: cy),
        control1: CGPoint(x: cx - rx, y: cy + ry * 0.75),
        control2: CGPoint(x: cx + rx, y: cy + ry * 0.75)
    )
    bodyPath.addCurve(
        to: CGPoint(x: cx - rx, y: cy),
        control1: CGPoint(x: cx + rx, y: cy - ry),
        control2: CGPoint(x: cx - rx, y: cy - ry)
    )
    bodyPath.closeSubpath()

    // Body fill - soft white/pink
    ctx.saveGState()
    ctx.setFillColor(red: 255/255, green: 240/255, blue: 242/255, alpha: alpha)
    ctx.addPath(bodyPath)
    ctx.fillPath()

    // Body stroke
    ctx.setStrokeColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.5 * alpha)
    ctx.setLineWidth(size * 0.02)
    ctx.addPath(bodyPath)
    ctx.strokePath()
    ctx.restoreGState()

    // Cheeks (blush)
    ctx.setFillColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.3 * alpha)
    let cheekR = size * 0.07
    ctx.fillEllipse(in: CGRect(x: cx - rx * 0.6 - cheekR, y: cy - ry * 0.05 - cheekR, width: cheekR * 2, height: cheekR * 2))
    ctx.fillEllipse(in: CGRect(x: cx + rx * 0.6 - cheekR, y: cy - ry * 0.05 - cheekR, width: cheekR * 2, height: cheekR * 2))

    // Eyes
    let eyeR = size * 0.035
    ctx.setFillColor(red: 74/255, green: 74/255, blue: 74/255, alpha: alpha)
    ctx.fillEllipse(in: CGRect(x: cx - rx * 0.32 - eyeR, y: cy - ry * 0.2 - eyeR, width: eyeR * 2, height: eyeR * 2))
    ctx.fillEllipse(in: CGRect(x: cx + rx * 0.32 - eyeR, y: cy - ry * 0.2 - eyeR, width: eyeR * 2, height: eyeR * 2))

    // Smile
    let smilePath = CGMutablePath()
    smilePath.move(to: CGPoint(x: cx - size * 0.08, y: cy + ry * 0.05))
    smilePath.addCurve(
        to: CGPoint(x: cx + size * 0.08, y: cy + ry * 0.05),
        control1: CGPoint(x: cx - size * 0.04, y: cy + ry * 0.25),
        control2: CGPoint(x: cx + size * 0.04, y: cy + ry * 0.25)
    )
    ctx.setStrokeColor(red: 74/255, green: 74/255, blue: 74/255, alpha: alpha)
    ctx.setLineWidth(size * 0.02)
    ctx.setLineCap(.round)
    ctx.addPath(smilePath)
    ctx.strokePath()
}

// MARK: - Big decorative mochis in background
drawMochi(ctx: ctx, cx: 85, cy: 70, size: 60, alpha: 0.15)
drawMochi(ctx: ctx, cx: 575, cy: 85, size: 45, alpha: 0.12)
drawMochi(ctx: ctx, cx: 620, cy: 330, size: 55, alpha: 0.13)
drawMochi(ctx: ctx, cx: 50, cy: 310, size: 40, alpha: 0.10)

// MARK: - Central mochi (large, prominent)
drawMochi(ctx: ctx, cx: width / 2, cy: 115, size: 120, alpha: 0.9)

// MARK: - Arrow (from left to right, between icon positions)
let arrowY: CGFloat = 275
let arrowStartX: CGFloat = 225
let arrowEndX: CGFloat = 435

ctx.saveGState()
ctx.setStrokeColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.6)
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)

// Dashed arrow line
let dashPattern: [CGFloat] = [8, 6]
ctx.setLineDash(phase: 0, lengths: dashPattern)
ctx.move(to: CGPoint(x: arrowStartX, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowEndX - 10, y: arrowY))
ctx.strokePath()

// Arrowhead (solid)
ctx.setLineDash(phase: 0, lengths: [])
ctx.setFillColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.6)
let arrowHead = CGMutablePath()
arrowHead.move(to: CGPoint(x: arrowEndX, y: arrowY))
arrowHead.addLine(to: CGPoint(x: arrowEndX - 14, y: arrowY - 8))
arrowHead.addLine(to: CGPoint(x: arrowEndX - 14, y: arrowY + 8))
arrowHead.closeSubpath()
ctx.addPath(arrowHead)
ctx.fillPath()
ctx.restoreGState()

// MARK: - Text "Glissez dans Applications"
let textY: CGFloat = 345
let text = "Glissez dans Applications" as NSString
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(red: 150/255, green: 120/255, blue: 125/255, alpha: 0.7)
]
let textSize = text.size(withAttributes: attributes)

// Draw text using NSGraphicsContext
NSGraphicsContext.saveGraphicsState()
let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: true)
NSGraphicsContext.current = nsCtx
text.draw(
    at: NSPoint(x: (width - textSize.width) / 2, y: textY),
    withAttributes: attributes
)
NSGraphicsContext.restoreGraphicsState()

// MARK: - Small decorative elements (rice grains)
ctx.setFillColor(red: 255/255, green: 158/255, blue: 170/255, alpha: 0.15)
let grainPositions: [(CGFloat, CGFloat, CGFloat)] = [
    (150, 150, 8), (510, 150, 6), (130, 350, 7),
    (530, 350, 5), (300, 50, 6), (380, 370, 7),
]
for (gx, gy, gs) in grainPositions {
    ctx.saveGState()
    ctx.translateBy(x: gx, y: gy)
    ctx.rotate(by: .pi / 4)
    ctx.fillEllipse(in: CGRect(x: -gs/2, y: -gs, width: gs, height: gs * 2))
    ctx.restoreGState()
}

// MARK: - Save to PNG
guard let image = ctx.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let outputURL = URL(fileURLWithPath: "/Users/aamsellem/dev/mochi-mochi/release/dmg-background.png")
guard let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else {
    print("Failed to create destination")
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)

print("Background generated: \(outputURL.path)")
