#!/usr/bin/env swift

import AppKit

/// Generates the app icon programmatically - a microphone with tape for "sticky" theme
func createAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let scale = size / 512.0

        // Background - fun gradient (teal to blue)
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.8, blue: 0.7, alpha: 1.0),
            NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
        ])

        let cornerRadius = size * 0.22
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        gradient?.draw(in: bgPath, angle: -45)

        // Draw microphone (white)
        NSColor.white.setFill()
        NSColor.white.setStroke()

        // Microphone body (capsule shape)
        let micWidth = 140.0 * scale
        let micHeight = 200.0 * scale
        let micX = (size - micWidth) / 2
        let micY = size * 0.32
        let micRect = NSRect(x: micX, y: micY, width: micWidth, height: micHeight)
        let micPath = NSBezierPath(roundedRect: micRect, xRadius: micWidth / 2, yRadius: micWidth / 2)
        micPath.fill()

        // Microphone grille lines
        NSColor(red: 0.75, green: 0.9, blue: 0.88, alpha: 1.0).setStroke()
        let lineSpacing = 26.0 * scale
        let lineInset = 25.0 * scale
        for i in 1...5 {
            let lineY = micY + micHeight * 0.22 + CGFloat(i) * lineSpacing
            if lineY < micY + micHeight - lineInset {
                let linePath = NSBezierPath()
                linePath.lineWidth = 4.0 * scale
                linePath.move(to: NSPoint(x: micX + lineInset, y: lineY))
                linePath.line(to: NSPoint(x: micX + micWidth - lineInset, y: lineY))
                linePath.stroke()
            }
        }

        // Microphone stand (arc)
        NSColor.white.setStroke()
        let standPath = NSBezierPath()
        standPath.lineWidth = 22.0 * scale
        standPath.lineCapStyle = .round

        let standWidth = 180.0 * scale
        let standCenterX = size / 2
        let standTop = micY - 8.0 * scale
        let standBottom = size * 0.15

        standPath.move(to: NSPoint(x: standCenterX - standWidth / 2, y: standTop))
        standPath.curve(to: NSPoint(x: standCenterX + standWidth / 2, y: standTop),
                       controlPoint1: NSPoint(x: standCenterX - standWidth / 2, y: standBottom),
                       controlPoint2: NSPoint(x: standCenterX + standWidth / 2, y: standBottom))
        standPath.stroke()

        // Stand vertical line
        let verticalPath = NSBezierPath()
        verticalPath.lineWidth = 22.0 * scale
        verticalPath.lineCapStyle = .round
        verticalPath.move(to: NSPoint(x: standCenterX, y: standBottom + 15 * scale))
        verticalPath.line(to: NSPoint(x: standCenterX, y: size * 0.07))
        verticalPath.stroke()

        // Stand base
        let baseWidth = 100.0 * scale
        let basePath = NSBezierPath()
        basePath.lineWidth = 22.0 * scale
        basePath.lineCapStyle = .round
        basePath.move(to: NSPoint(x: standCenterX - baseWidth / 2, y: size * 0.07))
        basePath.line(to: NSPoint(x: standCenterX + baseWidth / 2, y: size * 0.07))
        basePath.stroke()

        // === TAPE STRIPS for "sticky" theme ===

        // Tape strip 1 - diagonal across mic (yellow/tan tape)
        let tapeColor = NSColor(red: 1.0, green: 0.92, blue: 0.6, alpha: 0.9)
        tapeColor.setFill()

        let tape1Path = NSBezierPath()
        let tape1Width = 45.0 * scale
        let tape1StartX = micX - 20 * scale
        let tape1StartY = micY + micHeight * 0.5
        let tape1EndX = micX + micWidth + 20 * scale
        let tape1EndY = micY + micHeight * 0.7

        tape1Path.move(to: NSPoint(x: tape1StartX, y: tape1StartY + tape1Width/2))
        tape1Path.line(to: NSPoint(x: tape1EndX, y: tape1EndY + tape1Width/2))
        tape1Path.line(to: NSPoint(x: tape1EndX, y: tape1EndY - tape1Width/2))
        tape1Path.line(to: NSPoint(x: tape1StartX, y: tape1StartY - tape1Width/2))
        tape1Path.close()
        tape1Path.fill()

        // Tape strip 2 - opposite diagonal (slightly different color)
        let tape2Color = NSColor(red: 1.0, green: 0.88, blue: 0.5, alpha: 0.85)
        tape2Color.setFill()

        let tape2Path = NSBezierPath()
        let tape2Width = 40.0 * scale
        let tape2StartX = micX - 15 * scale
        let tape2StartY = micY + micHeight * 0.65
        let tape2EndX = micX + micWidth + 15 * scale
        let tape2EndY = micY + micHeight * 0.45

        tape2Path.move(to: NSPoint(x: tape2StartX, y: tape2StartY + tape2Width/2))
        tape2Path.line(to: NSPoint(x: tape2EndX, y: tape2EndY + tape2Width/2))
        tape2Path.line(to: NSPoint(x: tape2EndX, y: tape2EndY - tape2Width/2))
        tape2Path.line(to: NSPoint(x: tape2StartX, y: tape2StartY - tape2Width/2))
        tape2Path.close()
        tape2Path.fill()

        // Tape highlight lines (subtle texture)
        NSColor(white: 1.0, alpha: 0.3).setStroke()
        let highlightPath = NSBezierPath()
        highlightPath.lineWidth = 1.5 * scale
        highlightPath.move(to: NSPoint(x: tape1StartX + 10 * scale, y: tape1StartY))
        highlightPath.line(to: NSPoint(x: tape1EndX - 10 * scale, y: tape1EndY))
        highlightPath.stroke()

        return true
    }

    return image
}

func saveIcon(size: CGFloat, to path: String) {
    let image = createAppIcon(size: size)

    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: path))
        print("Created \(path)")
    }
}

// Generate all icon sizes
let basePath = "StickyMic/Assets.xcassets/AppIcon.appiconset"

let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_32x32.png"),
    (64, "icon_64x64.png"),
    (128, "icon_128x128.png"),
    (256, "icon_256x256.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_1024x1024.png")
]

for (size, filename) in sizes {
    saveIcon(size: size, to: "\(basePath)/\(filename)")
}

print("Done generating StickyMic app icons!")
