import AppKit

/// Creates the custom menu bar icon - a microphone with a small tape strip
enum MenuBarIcon {

    /// Creates the menu bar icon as a template image
    static func create(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSColor.black.setStroke()

            // Draw microphone body
            let micBodyRect = NSRect(x: 5, y: 6, width: 8, height: 10)
            let micBody = NSBezierPath(roundedRect: micBodyRect, xRadius: 4, yRadius: 4)
            micBody.fill()

            // Draw microphone stand (U shape)
            let standPath = NSBezierPath()
            standPath.lineWidth = 1.5
            standPath.move(to: NSPoint(x: 3, y: 9))
            standPath.curve(to: NSPoint(x: 9, y: 3),
                           controlPoint1: NSPoint(x: 3, y: 5),
                           controlPoint2: NSPoint(x: 5, y: 3))
            standPath.curve(to: NSPoint(x: 15, y: 9),
                           controlPoint1: NSPoint(x: 13, y: 3),
                           controlPoint2: NSPoint(x: 15, y: 5))
            standPath.stroke()

            // Draw stand base (vertical line)
            let basePath = NSBezierPath()
            basePath.lineWidth = 1.5
            basePath.move(to: NSPoint(x: 9, y: 3))
            basePath.line(to: NSPoint(x: 9, y: 1))
            basePath.stroke()

            // Draw small tape strip across mic (diagonal)
            let tapePath = NSBezierPath()
            tapePath.lineWidth = 3
            tapePath.move(to: NSPoint(x: 3, y: 12))
            tapePath.line(to: NSPoint(x: 15, y: 9))
            tapePath.stroke()

            return true
        }

        image.isTemplate = true
        return image
    }
}
