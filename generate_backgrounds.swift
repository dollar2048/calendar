import Foundation
import AppKit
import CoreGraphics

// Procedurally generates floral border backgrounds for the calendar.
// Output: backgrounds/bg-<palette>-<seed>.png (A4 landscape, 2x scale).

let pageWidth: CGFloat = 841.89
let pageHeight: CGFloat = 595.28
let scale: CGFloat = 2.0
let pixelWidth = Int(pageWidth * scale)
let pixelHeight = Int(pageHeight * scale)

struct Palette {
    let name: String
    let leafColors: [NSColor]
    let flowerColors: [NSColor]
    let berryColors: [NSColor]
    let accentColors: [NSColor]
}

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r/255, green: g/255, blue: b/255, alpha: a)
}

let palettes: [Palette] = [
    Palette(
        name: "vibrant",
        leafColors: [rgb(120, 190, 60), rgb(70, 160, 60), rgb(170, 215, 70), rgb(40, 120, 50), rgb(95, 175, 70)],
        flowerColors: [rgb(255, 200, 50), rgb(240, 100, 130), rgb(255, 170, 40), rgb(140, 110, 200)],
        berryColors: [rgb(230, 40, 50), rgb(200, 30, 60), rgb(245, 80, 60)],
        accentColors: [rgb(110, 80, 180), rgb(70, 130, 220), rgb(255, 120, 60)]
    ),
    Palette(
        name: "summer",
        leafColors: [rgb(110, 200, 90), rgb(70, 175, 80), rgb(160, 220, 100), rgb(50, 145, 75), rgb(200, 230, 110)],
        flowerColors: [rgb(255, 220, 60), rgb(255, 110, 130), rgb(255, 165, 70), rgb(255, 90, 110)],
        berryColors: [rgb(255, 80, 90), rgb(220, 50, 70), rgb(255, 150, 60)],
        accentColors: [rgb(70, 180, 230), rgb(255, 200, 80), rgb(255, 130, 90)]
    ),
    Palette(
        name: "sea",
        leafColors: [rgb(60, 165, 165), rgb(40, 130, 150), rgb(110, 200, 195), rgb(20, 100, 130), rgb(150, 215, 200)],
        flowerColors: [rgb(255, 195, 150), rgb(255, 230, 200), rgb(180, 220, 240), rgb(255, 150, 130)],
        berryColors: [rgb(255, 110, 90), rgb(220, 80, 100), rgb(70, 160, 200)],
        accentColors: [rgb(230, 200, 150), rgb(50, 110, 170), rgb(255, 180, 140)]
    ),
    Palette(
        name: "playgrounds",
        leafColors: [rgb(80, 200, 90), rgb(40, 160, 60), rgb(150, 220, 70), rgb(20, 130, 50)],
        flowerColors: [rgb(255, 215, 0), rgb(230, 50, 80), rgb(60, 140, 240), rgb(255, 130, 40)],
        berryColors: [rgb(230, 30, 50), rgb(255, 180, 0), rgb(60, 150, 230)],
        accentColors: [rgb(180, 80, 200), rgb(255, 110, 60), rgb(50, 180, 220)]
    ),
    Palette(
        name: "spring",
        leafColors: [rgb(140, 200, 70), rgb(95, 175, 65), rgb(180, 220, 90), rgb(60, 130, 55), rgb(110, 185, 80)],
        flowerColors: [rgb(255, 205, 70), rgb(245, 130, 160), rgb(170, 130, 230), rgb(255, 165, 90)],
        berryColors: [rgb(225, 50, 60), rgb(200, 35, 55)],
        accentColors: [rgb(140, 90, 200), rgb(90, 140, 220), rgb(255, 145, 60)]
    ),
    Palette(
        name: "autumn",
        leafColors: [rgb(220, 130, 50), rgb(170, 90, 40), rgb(240, 180, 60), rgb(120, 70, 30), rgb(190, 110, 50)],
        flowerColors: [rgb(255, 110, 50), rgb(255, 200, 60), rgb(220, 70, 80), rgb(255, 160, 80)],
        berryColors: [rgb(200, 40, 40), rgb(160, 60, 30), rgb(230, 80, 50)],
        accentColors: [rgb(160, 80, 30), rgb(200, 130, 50), rgb(140, 50, 80)]
    ),
    Palette(
        name: "pastel",
        leafColors: [rgb(170, 220, 170), rgb(130, 200, 160), rgb(210, 230, 180), rgb(100, 180, 140)],
        flowerColors: [rgb(255, 195, 210), rgb(225, 195, 240), rgb(255, 230, 170), rgb(255, 215, 180)],
        berryColors: [rgb(235, 130, 150), rgb(200, 150, 220), rgb(255, 160, 140)],
        accentColors: [rgb(180, 200, 230), rgb(230, 215, 170), rgb(220, 180, 230)]
    ),
    Palette(
        name: "tropical",
        leafColors: [rgb(50, 140, 90), rgb(80, 175, 105), rgb(20, 95, 65), rgb(120, 200, 95), rgb(60, 160, 110)],
        flowerColors: [rgb(255, 80, 140), rgb(255, 200, 50), rgb(80, 200, 220), rgb(255, 130, 60)],
        berryColors: [rgb(220, 50, 60), rgb(255, 130, 40), rgb(200, 30, 80)],
        accentColors: [rgb(170, 60, 160), rgb(50, 170, 200), rgb(255, 110, 60)]
    ),
    Palette(
        name: "monochrome-green",
        leafColors: [rgb(95, 155, 80), rgb(60, 120, 60), rgb(140, 195, 100), rgb(35, 95, 50), rgb(180, 215, 120)],
        flowerColors: [rgb(200, 220, 140), rgb(230, 240, 180), rgb(170, 200, 100)],
        berryColors: [rgb(70, 110, 55), rgb(130, 165, 70)],
        accentColors: [rgb(110, 145, 70), rgb(160, 185, 90)]
    )
]

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

func randUnit(_ rng: inout SeededRNG) -> CGFloat {
    CGFloat(rng.next() % 10_000) / 10_000.0
}

func randRange(_ rng: inout SeededRNG, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    lo + randUnit(&rng) * (hi - lo)
}

func pick<T>(_ array: [T], _ rng: inout SeededRNG) -> T {
    array[Int(rng.next() % UInt64(array.count))]
}

// Drawing primitives — all in landscape 841.89 x 595.28 coords.

func drawLeaf(at point: CGPoint, length: CGFloat, angle: CGFloat, color: NSColor, in ctx: CGContext) {
    ctx.saveGState()
    ctx.translateBy(x: point.x, y: point.y)
    ctx.rotate(by: angle)

    let path = NSBezierPath()
    let width = length * 0.45
    path.move(to: .zero)
    path.curve(to: CGPoint(x: length, y: 0),
               controlPoint1: CGPoint(x: length * 0.3, y: width),
               controlPoint2: CGPoint(x: length * 0.7, y: width))
    path.curve(to: .zero,
               controlPoint1: CGPoint(x: length * 0.7, y: -width),
               controlPoint2: CGPoint(x: length * 0.3, y: -width))
    path.close()

    color.setFill()
    path.fill()

    NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.85).setStroke()
    path.lineWidth = 1.6
    path.stroke()

    let vein = NSBezierPath()
    vein.move(to: .zero)
    vein.line(to: CGPoint(x: length, y: 0))
    NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.65).setStroke()
    vein.lineWidth = 1.0
    vein.stroke()

    // Side veins for richer leaf detail.
    let sideVeinCount = 3
    for k in 1...sideVeinCount {
        let t = CGFloat(k) / CGFloat(sideVeinCount + 1)
        let baseX = length * t
        let span = (length * 0.45) * (1 - abs(t - 0.5) * 1.3)
        let upper = NSBezierPath()
        upper.move(to: CGPoint(x: baseX, y: 0))
        upper.line(to: CGPoint(x: baseX + span * 0.4, y: span))
        let lower = NSBezierPath()
        lower.move(to: CGPoint(x: baseX, y: 0))
        lower.line(to: CGPoint(x: baseX + span * 0.4, y: -span))
        NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.45).setStroke()
        upper.lineWidth = 0.7
        lower.lineWidth = 0.7
        upper.stroke()
        lower.stroke()
    }

    ctx.restoreGState()
}

func drawFlower(at point: CGPoint, radius: CGFloat, petals: Int, color: NSColor, centerColor: NSColor, in ctx: CGContext) {
    ctx.saveGState()
    ctx.translateBy(x: point.x, y: point.y)

    for i in 0..<petals {
        let angle = (CGFloat.pi * 2 / CGFloat(petals)) * CGFloat(i)
        let petal = NSBezierPath()
        let pw = radius * 0.55
        petal.move(to: .zero)
        let tipX = cos(angle) * radius
        let tipY = sin(angle) * radius
        let leftX = cos(angle + .pi/2) * pw * 0.5
        let leftY = sin(angle + .pi/2) * pw * 0.5
        let rightX = cos(angle - .pi/2) * pw * 0.5
        let rightY = sin(angle - .pi/2) * pw * 0.5
        petal.curve(to: CGPoint(x: tipX, y: tipY),
                    controlPoint1: CGPoint(x: leftX, y: leftY),
                    controlPoint2: CGPoint(x: tipX + leftX * 0.4, y: tipY + leftY * 0.4))
        petal.curve(to: .zero,
                    controlPoint1: CGPoint(x: tipX + rightX * 0.4, y: tipY + rightY * 0.4),
                    controlPoint2: CGPoint(x: rightX, y: rightY))
        petal.close()
        color.setFill()
        petal.fill()
        NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.85).setStroke()
        petal.lineWidth = 1.3
        petal.stroke()
    }

    let center = NSBezierPath(ovalIn: CGRect(x: -radius * 0.25, y: -radius * 0.25, width: radius * 0.5, height: radius * 0.5))
    centerColor.setFill()
    center.fill()
    NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.9).setStroke()
    center.lineWidth = 1.3
    center.stroke()

    ctx.restoreGState()
}

func drawBerryCluster(at point: CGPoint, radius: CGFloat, count: Int, color: NSColor, in ctx: CGContext, rng: inout SeededRNG) {
    for _ in 0..<count {
        let dx = randRange(&rng, -radius * 1.4, radius * 1.4)
        let dy = randRange(&rng, -radius * 1.4, radius * 1.4)
        let r = radius * randRange(&rng, 0.7, 1.1)
        let path = NSBezierPath(ovalIn: CGRect(x: point.x + dx - r, y: point.y + dy - r, width: r * 2, height: r * 2))
        color.setFill()
        path.fill()
        NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.9).setStroke()
        path.lineWidth = 1.1
        path.stroke()

        let highlight = NSBezierPath(ovalIn: CGRect(x: point.x + dx - r * 0.35, y: point.y + dy - r * 0.05, width: r * 0.4, height: r * 0.4))
        NSColor(calibratedWhite: 1, alpha: 0.5).setFill()
        highlight.fill()
    }
}

func drawStem(from start: CGPoint, to end: CGPoint, control: CGPoint, color: NSColor, in ctx: CGContext) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(to: end, controlPoint1: control, controlPoint2: control)

    NSColor(calibratedRed: 0.32, green: 0.10, blue: 0.20, alpha: 0.7).setStroke()
    path.lineWidth = 2.6
    path.lineCapStyle = .round
    path.stroke()

    color.setStroke()
    path.lineWidth = 2.0
    path.stroke()
}

enum Edge { case top, bottom, left, right }

func placeOnBorder(edge: Edge, t: CGFloat, depth: CGFloat) -> CGPoint {
    switch edge {
    case .top:    return CGPoint(x: t * pageWidth, y: pageHeight - depth)
    case .bottom: return CGPoint(x: t * pageWidth, y: depth)
    case .left:   return CGPoint(x: depth, y: t * pageHeight)
    case .right:  return CGPoint(x: pageWidth - depth, y: t * pageHeight)
    }
}

func renderBackground(palette: Palette, seed: UInt64) -> Data? {
    var rng = SeededRNG(seed: seed)

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
    guard let ctx = CGContext(
        data: nil,
        width: pixelWidth,
        height: pixelHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.scaleBy(x: scale, y: scale)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx

    let edges: [Edge] = [.top, .bottom, .left, .right]
    let borderDepthMax: CGFloat = 140

    // Pass 1: stems + leaves (background layer).
    for edge in edges {
        let segments = 26
        for i in 0..<segments {
            let t = CGFloat(i) / CGFloat(segments) + randRange(&rng, -0.02, 0.02)
            let depth = randRange(&rng, 8, borderDepthMax)
            let anchor = placeOnBorder(edge: edge, t: max(0, min(1, t)), depth: depth)

            // Stem reaching inward.
            let inward: CGVector
            switch edge {
            case .top: inward = CGVector(dx: 0, dy: -1)
            case .bottom: inward = CGVector(dx: 0, dy: 1)
            case .left: inward = CGVector(dx: 1, dy: 0)
            case .right: inward = CGVector(dx: -1, dy: 0)
            }
            let length = randRange(&rng, 40, 130)
            let tip = CGPoint(x: anchor.x + inward.dx * length, y: anchor.y + inward.dy * length)
            let curve = randRange(&rng, -35, 35)
            let perp = CGVector(dx: inward.dy, dy: -inward.dx)
            let control = CGPoint(x: (anchor.x + tip.x)/2 + perp.dx * curve, y: (anchor.y + tip.y)/2 + perp.dy * curve)
            drawStem(from: anchor, to: tip, control: control, color: pick(palette.leafColors, &rng), in: ctx)

            // Leaves along stem.
            let leafCount = Int(randRange(&rng, 2, 5))
            for j in 0..<leafCount {
                let s = CGFloat(j + 1) / CGFloat(leafCount + 1)
                let pos = CGPoint(x: anchor.x + (tip.x - anchor.x) * s, y: anchor.y + (tip.y - anchor.y) * s)
                let leafLen = randRange(&rng, 36, 95)
                let leafAngle = atan2(inward.dy, inward.dx) + randRange(&rng, -1.3, 1.3)
                drawLeaf(at: pos, length: leafLen, angle: leafAngle, color: pick(palette.leafColors, &rng), in: ctx)
            }
        }
    }

    // Pass 2: flowers + berries (foreground accents).
    for edge in edges {
        let bursts = Int(randRange(&rng, 10, 18))
        for _ in 0..<bursts {
            let t = randUnit(&rng)
            let depth = randRange(&rng, 15, borderDepthMax - 10)
            let pos = placeOnBorder(edge: edge, t: t, depth: depth)
            let kind = rng.next() % 3
            switch kind {
            case 0:
                drawFlower(
                    at: pos,
                    radius: randRange(&rng, 18, 36),
                    petals: [5, 6, 8, 10].randomElement(using: &rng) ?? 5,
                    color: pick(palette.flowerColors, &rng),
                    centerColor: pick(palette.accentColors, &rng),
                    in: ctx
                )
            case 1:
                drawBerryCluster(
                    at: pos,
                    radius: randRange(&rng, 6, 11),
                    count: Int(randRange(&rng, 4, 9)),
                    color: pick(palette.berryColors, &rng),
                    in: ctx,
                    rng: &rng
                )
            default:
                drawFlower(
                    at: pos,
                    radius: randRange(&rng, 8, 14),
                    petals: 5,
                    color: pick(palette.accentColors, &rng),
                    centerColor: pick(palette.flowerColors, &rng),
                    in: ctx
                )
            }
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])
}

let cwd = FileManager.default.currentDirectoryPath
let outputDir = "\(cwd)/backgrounds"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let countArg = CommandLine.arguments.dropFirst().first.flatMap(Int.init) ?? 1
let variantsPerPalette = max(1, countArg)

var generated: [String] = []
for palette in palettes {
    for variant in 0..<variantsPerPalette {
        let seed = UInt64(abs(palette.name.hashValue)) &+ UInt64(variant) &* 7919
        guard let data = renderBackground(palette: palette, seed: seed) else { continue }
        let suffix = variantsPerPalette > 1 ? "-\(variant + 1)" : ""
        let path = "\(outputDir)/bg-\(palette.name)\(suffix).png"
        do {
            try data.write(to: URL(fileURLWithPath: path))
            generated.append(path)
        } catch {
            FileHandle.standardError.write(Data("Failed to write \(path): \(error)\n".utf8))
        }
    }
}

print("Generated \(generated.count) backgrounds in \(outputDir)")
for path in generated { print("  \(path)") }
