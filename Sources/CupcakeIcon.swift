import AppKit

/// Menu bar icons. Both are template images so macOS tints them for light and dark menu bars.
enum CupcakeIcon {
    private static let size = NSSize(width: 16, height: 16)

    /// The normal cupcake. Falls back to a drawn one if the image is missing from the bundle.
    static func make() -> NSImage {
        guard let image = Bundle.main.image(forResource: "cupcakeTemplate") else {
            return drawn()
        }
        image.size = size
        image.isTemplate = true
        image.accessibilityDescription = "Cupcake"
        return image
    }

    /// The cupcake with its frosting filled in, flashed briefly after copying something.
    static func filled() -> NSImage? {
        let image = Bundle.main.image(forResource: "cupcakeFilledTemplate")
            ?? NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Copied")
        image?.size = size
        image?.isTemplate = true
        image?.accessibilityDescription = "Copied"
        return image
    }

    private static func drawn() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setFill()

            let wrapper = NSBezierPath()
            wrapper.move(to: NSPoint(x: 3.5, y: 8))
            wrapper.line(to: NSPoint(x: 14.5, y: 8))
            wrapper.line(to: NSPoint(x: 12.5, y: 1.5))
            wrapper.line(to: NSPoint(x: 5.5, y: 1.5))
            wrapper.close()
            wrapper.fill()

            // Cut the pleats out of the wrapper
            NSGraphicsContext.current?.compositingOperation = .clear
            let pleats = NSBezierPath()
            pleats.lineWidth = 1
            pleats.move(to: NSPoint(x: 7.3, y: 8))
            pleats.line(to: NSPoint(x: 7.9, y: 1.5))
            pleats.move(to: NSPoint(x: 10.7, y: 8))
            pleats.line(to: NSPoint(x: 10.1, y: 1.5))
            pleats.stroke()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            let frosting = NSBezierPath()
            frosting.appendOval(in: NSRect(x: 2.5, y: 8.8, width: 5.5, height: 4.4))
            frosting.appendOval(in: NSRect(x: 6.2, y: 9.2, width: 5.6, height: 4.8))
            frosting.appendOval(in: NSRect(x: 10.0, y: 8.8, width: 5.5, height: 4.4))
            frosting.appendOval(in: NSRect(x: 5.0, y: 11.2, width: 8.0, height: 4.2))
            frosting.fill()

            let cherry = NSBezierPath(ovalIn: NSRect(x: 7.6, y: 15.0, width: 2.8, height: 2.8))
            cherry.fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Cupcake"
        return image
    }
}
