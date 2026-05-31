import Foundation
import AppKit
import CoreGraphics

func prompt(_ message: String) -> String {
    FileHandle.standardError.write(Data(message.utf8))
    return readLine() ?? ""
}

func readMonth() -> Int {
    while true {
        let raw = prompt("Month (1-12): ").trimmingCharacters(in: .whitespaces)
        if let value = Int(raw), (1...12).contains(value) { return value }
        FileHandle.standardError.write(Data("Invalid month. Try again.\n".utf8))
    }
}

func readYear() -> Int {
    while true {
        let raw = prompt("Year (e.g. 2026): ").trimmingCharacters(in: .whitespaces)
        if let value = Int(raw), (1900...2999).contains(value) { return value }
        FileHandle.standardError.write(Data("Invalid year. Try again.\n".utf8))
    }
}

let month = readMonth()
let year = readYear()

let calendar = Calendar(identifier: .gregorian)
let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
let monthRange = calendar.range(of: .day, in: .month, for: monthDate)!
let firstWeekday = calendar.component(.weekday, from: monthDate)
let mondayBasedOffset = (firstWeekday + 5) % 7
let totalCells = mondayBasedOffset + monthRange.count
let rows = Int(ceil(Double(totalCells) / 7.0))

let monthFormatter = DateFormatter()
monthFormatter.locale = Locale(identifier: "en_US")
monthFormatter.dateFormat = "LLLL"
let monthName = monthFormatter.string(from: monthDate)

let cwd = FileManager.default.currentDirectoryPath

let pageWidth: CGFloat = 841.89
let pageHeight: CGFloat = 595.28

func resolveBackgroundPaths() -> [String] {
    let args = CommandLine.arguments.dropFirst()
    if let arg = args.first, FileManager.default.fileExists(atPath: arg) {
        return [arg]
    }
    let backgroundsDir = "\(cwd)/backgrounds"
    if let entries = try? FileManager.default.contentsOfDirectory(atPath: backgroundsDir) {
        let images = entries
            .filter { $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".jpg") }
            .shuffled()
        if !images.isEmpty {
            // Group by palette name (strip variant suffix like "-1", "-2").
            // Filename format: "bg-<palette>-<variant>.png" or "bg-<palette>.png".
            func paletteKey(for filename: String) -> String {
                let stem = ((filename as NSString).deletingPathExtension as String)
                let parts = stem.split(separator: "-")
                guard parts.count >= 2 else { return stem }
                if parts.count >= 3, Int(parts.last!) != nil {
                    return parts.dropLast().joined(separator: "-")
                }
                return stem
            }

            var seenPalettes = Set<String>()
            var picks: [String] = []
            for image in images {
                let key = paletteKey(for: image)
                if seenPalettes.insert(key).inserted {
                    picks.append(image)
                    if picks.count == 3 { break }
                }
            }
            // If fewer than 3 distinct palettes, fill from remaining.
            if picks.count < 3 {
                for image in images where !picks.contains(image) {
                    picks.append(image)
                    if picks.count == 3 { break }
                }
            }
            return picks.map { "\(backgroundsDir)/\($0)" }
        }
    }
    let legacy = "\(cwd)/image-1776956639655.png"
    if FileManager.default.fileExists(atPath: legacy) { return [legacy] }
    return [""]
}

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
    CGRect(x: x, y: pageHeight - y - height, width: width, height: height)
}

func drawText(
    _ text: String,
    in rect: CGRect,
    font: NSFont,
    color: NSColor = .black,
    alignment: NSTextAlignment = .left,
    kern: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: kern
    ]
    text.draw(in: rect, withAttributes: attributes)
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()

    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func renderPDF(backgroundPath: String, outputPath: String) -> Bool {
    var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    guard
        let consumer = CGDataConsumer(url: URL(fileURLWithPath: outputPath) as CFURL),
        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    else {
        fputs("Failed to create PDF context for \(outputPath).\n", stderr)
        return false
    }

    context.beginPDFPage(nil)
    context.setFillColor(NSColor.white.cgColor)
    context.fill(mediaBox)

    let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    if !backgroundPath.isEmpty, let backgroundImage = NSImage(contentsOfFile: backgroundPath) {
        backgroundImage.draw(in: mediaBox)
    }

    let outerMargin: CGFloat = 36
    let titleHeight: CGFloat = 56
    let weekdayHeaderHeight: CGFloat = 32
    let spacingAfterTitle: CGFloat = 18
    let gridTop = outerMargin + titleHeight + spacingAfterTitle
    let gridHeight = pageHeight - gridTop - outerMargin
    let cellWidth = (pageWidth - (outerMargin * 2)) / 7.0
    let cellHeight = (gridHeight - weekdayHeaderHeight) / CGFloat(rows)

    let titleRect = rectFromTop(x: outerMargin, y: outerMargin - 6, width: pageWidth - outerMargin * 2, height: titleHeight)
    let titleCardRect = titleRect.insetBy(dx: -12, dy: -4)
    drawRoundedRect(
        titleCardRect,
        radius: 18,
        fill: NSColor(calibratedWhite: 1, alpha: 0.85)
    )
    let titleFont = NSFont(name: "SnellRoundhand-Bold", size: 38)
        ?? NSFont(name: "Didot-Italic", size: 36)
        ?? NSFont(name: "Baskerville-Italic", size: 36)
        ?? NSFont.systemFont(ofSize: 36, weight: .medium)
    drawText(
        "\(monthName) \(year)",
        in: titleRect,
        font: titleFont,
        color: NSColor(calibratedWhite: 0.10, alpha: 0.92),
        alignment: .center,
        kern: 1.2
    )

    let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let borderColor = NSColor(calibratedWhite: 0.55, alpha: 0.85).cgColor
    let weekdayCellFill = NSColor.white.cgColor
    let weekendCellFill = NSColor(calibratedRed: 0.99, green: 0.90, blue: 0.90, alpha: 1.0).cgColor
    let weekdayHeaderFill = NSColor.white.cgColor
    let weekendHeaderFill = NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.85, alpha: 1.0).cgColor
    let weekdayTextColor = NSColor(calibratedWhite: 0.18, alpha: 1)
    let weekendTextColor = NSColor(calibratedRed: 0.72, green: 0.22, blue: 0.22, alpha: 1.0)
    let weekdayDayNumberColor = NSColor(calibratedWhite: 0.16, alpha: 0.85)
    let weekendDayNumberColor = NSColor(calibratedRed: 0.72, green: 0.22, blue: 0.22, alpha: 0.92)

    func isWeekend(_ column: Int) -> Bool { column >= 5 }

    for column in 0..<7 {
        let x = outerMargin + CGFloat(column) * cellWidth
        let headerRect = rectFromTop(x: x, y: gridTop, width: cellWidth, height: weekdayHeaderHeight)
        context.setFillColor(isWeekend(column) ? weekendHeaderFill : weekdayHeaderFill)
        context.fill(headerRect)
        context.setStrokeColor(borderColor)
        context.stroke(headerRect, width: 1)

        drawText(
            weekdayNames[column],
            in: headerRect.insetBy(dx: 6, dy: 6),
            font: NSFont.boldSystemFont(ofSize: 13),
            color: isWeekend(column) ? weekendTextColor : weekdayTextColor,
            alignment: .center
        )
    }

    for row in 0..<rows {
        for column in 0..<7 {
            let x = outerMargin + CGFloat(column) * cellWidth
            let y = gridTop + weekdayHeaderHeight + CGFloat(row) * cellHeight
            let cellRect = rectFromTop(x: x, y: y, width: cellWidth, height: cellHeight)

            context.setFillColor(isWeekend(column) ? weekendCellFill : weekdayCellFill)
            context.fill(cellRect)

            context.setStrokeColor(borderColor)
            context.stroke(cellRect, width: 1)

            let dayIndex = row * 7 + column - mondayBasedOffset + 1
            guard monthRange.contains(dayIndex) else { continue }

            let numberRect = cellRect.insetBy(dx: 8, dy: 8)
            drawText(
                "\(dayIndex)",
                in: numberRect,
                font: NSFont.systemFont(ofSize: 15, weight: .regular),
                color: isWeekend(column) ? weekendDayNumberColor : weekdayDayNumberColor,
                alignment: .left
            )
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
    context.closePDF()
    return true
}

let backgroundPaths = resolveBackgroundPaths()
var producedPaths: [String] = []

for path in backgroundPaths {
    let baseName = (path as NSString).lastPathComponent
    let stem = (baseName as NSString).deletingPathExtension
    let suffix = stem.isEmpty ? "" : "-\(stem)"
    let outputPath = "\(cwd)/\(monthName)-\(year)-calendar-A4-landscape\(suffix).pdf"
    if renderPDF(backgroundPath: path, outputPath: outputPath) {
        producedPaths.append(outputPath)
    }
}

print("Generated \(producedPaths.count) PDF(s):")
for p in producedPaths { print("  \(p)") }
