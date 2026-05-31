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
        name: "spring",
        leafColors: [rgb(120, 170, 70), rgb(80, 140, 60), rgb(160, 200, 90), rgb(60, 110, 50)],
        flowerColors: [rgb(245, 190, 90), rgb(230, 130, 150), rgb(150, 130, 200)],
        berryColors: [rgb(210, 60, 60), rgb(180, 40, 50)],
        accentColors: [rgb(120, 90, 140), rgb(90, 130, 180)]
    ),
    Palette(
        name: "autumn",
        leafColors: [rgb(180, 110, 60), rgb(130, 80, 40), rgb(200, 150, 70), rgb(90, 60, 30)],
        flowerColors: [rgb(220, 90, 50), rgb(240, 170, 60), rgb(170, 60, 70)],
        berryColors: [rgb(150, 40, 30), rgb(110, 50, 30)],
        accentColors: [rgb(120, 70, 30), rgb(80, 50, 20)]
    ),
    Palette(
        name: "pastel",
        leafColors: [rgb(170, 200, 170), rgb(140, 180, 150), rgb(200, 220, 190)],
        flowerColors: [rgb(245, 200, 210), rgb(220, 200, 230), rgb(250, 230, 200)],
        berryColors: [rgb(220, 140, 150), rgb(190, 160, 200)],
        accentColors: [rgb(180, 200, 220), rgb(220, 210, 180)]
    ),
    Palette(
        name: "tropical",
        leafColors: [rgb(40, 110, 80), rgb(70, 150, 100), rgb(20, 80, 60), rgb(100, 170, 90)],
        flowerColors: [rgb(230, 70, 130), rgb(250, 180, 60), rgb(80, 180, 200)],
        berryColors: [rgb(200, 50, 60), rgb(230, 130, 40)],
        accentColors: [rgb(140, 50, 130), rgb(50, 140, 160)]
    ),
    Palette(
        name: "monochrome-green",
        leafColors: [rgb(80, 130, 70), rgb(50, 100, 50), rgb(120, 170, 90), rgb(30, 80, 40), rgb(160, 190, 110)],
        flowerColors: [rgb(180, 200, 130), rgb(220, 230, 180)],
        berryColors: [rgb(60, 90, 50), rgb(110, 140, 60)],
        accentColors: [rgb(90, 120, 60), rgb(140, 160, 80)]
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

    NSColor(calibratedWhite: 0.15, alpha: 0.45).setStroke()
    path.lineWidth = 1.2
    path.stroke()

    let vein = NSBezierPath()
    vein.move(to: .zero)
    vein.line(to: CGPoint(x: length, y: 0))
    NSColor(calibratedWhite: 0.15, alpha: 0.35).setStroke()
    vein.lineWidth = 0.8
    vein.stroke()

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
        NSColor(calibratedWhite: 0.15, alpha: 0.45).setStroke()
        petal.lineWidth = 0.9
        petal.stroke()
    }

    let center = NSBezierPath(ovalIn: CGRect(x: -radius * 0.25, y: -radius * 0.25, width: radius * 0.5, height: radius * 0.5))
    centerColor.setFill()
    center.fill()
    NSColor(calibratedWhite: 0.15, alpha: 0.5).setStroke()
    center.lineWidth = 0.9
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
        NSColor(calibratedWhite: 0.15, alpha: 0.5).setStroke()
        path.lineWidth = 0.8
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
    color.setStroke()
    path.lineWidth = 1.6
    path.lineCapStyle = .round
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
    let borderDepthMax: CGFloat = 110

    // Pass 1: stems + leaves (background layer).
    for edge in edges {
        let segments = 18
        for i in 0..<segments {
            let t = CGFloat(i) / CGFloat(segments) + randRange(&rng, -0.02, 0.02)
            let depth = randRange(&rng, 10, borderDepthMax)
            let anchor = placeOnBorder(edge: edge, t: max(0, min(1, t)), depth: depth)

            // Stem reaching inward.
            let inward: CGVector
            switch edge {
            case .top: inward = CGVector(dx: 0, dy: -1)
            case .bottom: inward = CGVector(dx: 0, dy: 1)
            case .left: inward = CGVector(dx: 1, dy: 0)
            case .right: inward = CGVector(dx: -1, dy: 0)
            }
            let length = randRange(&rng, 30, 90)
            let tip = CGPoint(x: anchor.x + inward.dx * length, y: anchor.y + inward.dy * length)
            let curve = randRange(&rng, -25, 25)
            let perp = CGVector(dx: inward.dy, dy: -inward.dx)
            let control = CGPoint(x: (anchor.x + tip.x)/2 + perp.dx * curve, y: (anchor.y + tip.y)/2 + perp.dy * curve)
            drawStem(from: anchor, to: tip, control: control, color: pick(palette.leafColors, &rng), in: ctx)

            // Leaves along stem.
            let leafCount = Int(randRange(&rng, 1, 4))
            for j in 0..<leafCount {
                let s = CGFloat(j + 1) / CGFloat(leafCount + 1)
                let pos = CGPoint(x: anchor.x + (tip.x - anchor.x) * s, y: anchor.y + (tip.y - anchor.y) * s)
                let leafLen = randRange(&rng, 28, 60)
                let leafAngle = atan2(inward.dy, inward.dx) + randRange(&rng, -1.2, 1.2)
                drawLeaf(at: pos, length: leafLen, angle: leafAngle, color: pick(palette.leafColors, &rng), in: ctx)
            }
        }
    }

    // Pass 2: flowers + berries (foreground accents).
    for edge in edges {
        let bursts = Int(randRange(&rng, 6, 12))
        for _ in 0..<bursts {
            let t = randUnit(&rng)
            let depth = randRange(&rng, 15, borderDepthMax - 10)
            let pos = placeOnBorder(edge: edge, t: t, depth: depth)
            let kind = rng.next() % 3
            switch kind {
            case 0:
                drawFlower(
                    at: pos,
                    radius: randRange(&rng, 14, 28),
                    petals: [5, 6, 8].randomElement(using: &rng) ?? 5,
                    color: pick(palette.flowerColors, &rng),
                    centerColor: pick(palette.accentColors, &rng),
                    in: ctx
                )
            case 1:
                drawBerryCluster(
                    at: pos,
                    radius: randRange(&rng, 5, 9),
                    count: Int(randRange(&rng, 3, 7)),
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
