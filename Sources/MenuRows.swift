import AppKit

/// Measurements shared by both kinds of menu row.
@MainActor
enum MenuStyle {
    static let minWidth: CGFloat = 325
    static let leftInset: CGFloat = 14
    static let rightInset: CGFloat = 16

    // macOS 26 (Tahoe) uses taller, rounder menu rows.
    static let isTahoe = ProcessInfo.processInfo.isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0))
    static var rowHeight: CGFloat { isTahoe ? 24 : 22 }
    static var cornerRadius: CGFloat { isTahoe ? 7 : 4 }

    static var font: NSFont { NSFont.menuFont(ofSize: 0) }
    static var boldFont: NSFont { NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
}

extension NSView {
    /// Draws a single line of text vertically centred in the view and returns its size.
    @discardableResult
    func drawCentered(_ text: String, x: CGFloat, attributes: [NSAttributedString.Key: Any]) -> NSSize {
        let string = text as NSString
        let size = string.size(withAttributes: attributes)
        string.draw(at: NSPoint(x: x, y: (bounds.height - size.height) / 2), withAttributes: attributes)
        return size
    }
}

// MARK: - Address row

/// A label on the left and a value on the right edge, e.g. "Gateway IP   192.168.3.1".
/// Menu items with custom views don't highlight or respond to clicks on their own,
/// so this view draws its own hover state and handles the click.
final class AddressRowView: NSView {
    private let label: String
    private let value: String
    private let enabled: Bool
    private let onClick: () -> Void

    private static let hoverColor = NSColor(srgbRed: 0.268, green: 0.268, blue: 0.278, alpha: 1)        // #444447
    private static let hoverBorderColor = NSColor(srgbRed: 0.46, green: 0.46, blue: 0.49, alpha: 1)     // #76767C
    private static let copyIconGap: CGFloat = 6

    private static var labelFont: NSFont { MenuStyle.boldFont }
    private static var valueFont: NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: MenuStyle.font.pointSize, weight: .regular)
    }

    init(label: String, value: String, enabled: Bool, onClick: @escaping () -> Void) {
        self.label = label
        self.value = value
        self.enabled = enabled
        self.onClick = onClick

        let labelWidth = (label as NSString).size(withAttributes: [.font: Self.labelFont]).width
        let valueWidth = (value as NSString).size(withAttributes: [.font: Self.valueFont]).width
        // The gap between label and value leaves room for the copy icon on hover
        let width = ceil(MenuStyle.leftInset + labelWidth + 48 + valueWidth + MenuStyle.rightInset)

        super.init(frame: NSRect(x: 0, y: 0, width: max(width, MenuStyle.minWidth), height: MenuStyle.rowHeight))
        autoresizingMask = [.width]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var isHovered: Bool {
        enabled && (enclosingMenuItem?.isHighlighted ?? false)
    }

    override func draw(_ dirtyRect: NSRect) {
        let hovered = isHovered
        if hovered {
            drawHighlight()
        }

        let textColor: NSColor
        if !enabled {
            textColor = .disabledControlTextColor
        } else {
            textColor = hovered ? .white : .labelColor
        }

        drawCentered(label, x: MenuStyle.leftInset,
                     attributes: [.font: Self.labelFont, .foregroundColor: textColor])

        let valueAttributes: [NSAttributedString.Key: Any] = [.font: Self.valueFont, .foregroundColor: textColor]
        let valueWidth = (value as NSString).size(withAttributes: valueAttributes).width
        let valueX = bounds.width - MenuStyle.rightInset - valueWidth
        drawCentered(value, x: valueX, attributes: valueAttributes)

        if hovered {
            drawCopyIcon(rightEdge: valueX - Self.copyIconGap)
        }
    }

    private func drawHighlight() {
        // Half-point inset keeps the 1pt border on whole pixels
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 5.5, dy: 0.5),
                                xRadius: MenuStyle.cornerRadius, yRadius: MenuStyle.cornerRadius)
        Self.hoverColor.setFill()
        path.fill()
        Self.hoverBorderColor.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func drawCopyIcon(rightEdge: CGFloat) {
        let config = NSImage.SymbolConfiguration(pointSize: 9, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor.white.withAlphaComponent(0.6)]))
        guard let icon = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")?
            .withSymbolConfiguration(config) else { return }

        let size = icon.size
        icon.draw(in: NSRect(x: rightEdge - size.width, y: (bounds.height - size.height) / 2,
                             width: size.width, height: size.height))
    }

    override func mouseUp(with event: NSEvent) {
        guard enabled else { return }
        enclosingMenuItem?.menu?.cancelTracking()
        onClick()
    }
}

// MARK: - Status row

/// The coloured row at the top of the menu: "Network: <name>" on the left,
/// the connection status on the right. It's only clickable when it offers "Allow in Settings…".
final class StatusRowView: NSView {
    enum State { case online, vpn, limited, offline }
    enum NetworkStyle { case value, missing, action }

    private let state: State
    private let status: String
    private let network: String
    private let networkStyle: NetworkStyle
    private let onClick: (() -> Void)?

    private static let networkLabel = "Network:"
    /// How far the system colours are darkened towards black so white text stays readable.
    private static let darkening: CGFloat = 0.20
    private static let hoverDarkening: CGFloat = 0.30

    init(state: State, status: String, network: String, networkStyle: NetworkStyle, onClick: (() -> Void)?) {
        self.state = state
        self.status = status
        self.network = network
        self.networkStyle = networkStyle
        self.onClick = onClick

        func textWidth(_ text: String, _ font: NSFont) -> CGFloat {
            (text as NSString).size(withAttributes: [.font: font]).width
        }
        let width = MenuStyle.leftInset
            + textWidth(Self.networkLabel, MenuStyle.boldFont) + 4
            + textWidth(network, MenuStyle.font) + 32
            + textWidth(status, MenuStyle.font)
            + MenuStyle.rightInset

        super.init(frame: NSRect(x: 0, y: 0, width: max(ceil(width), MenuStyle.minWidth), height: MenuStyle.rowHeight))
        autoresizingMask = [.width]
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityLabel("\(Self.networkLabel) \(network). \(status)")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var baseColor: NSColor {
        switch state {
        case .online: return .systemGreen
        case .vpn: return .systemPurple
        case .limited: return .systemOrange
        case .offline: return .systemRed
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let hovered = onClick != nil && (enclosingMenuItem?.isHighlighted ?? false)
        let darkening = hovered ? Self.hoverDarkening : Self.darkening
        let background = baseColor.blended(withFraction: darkening, of: .black) ?? baseColor
        background.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0),
                     xRadius: MenuStyle.cornerRadius, yRadius: MenuStyle.cornerRadius).fill()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 1.5

        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: MenuStyle.font, .foregroundColor: NSColor.white, .shadow: shadow,
        ]
        let statusWidth = (status as NSString).size(withAttributes: statusAttributes).width
        drawCentered(status, x: bounds.width - MenuStyle.rightInset - statusWidth, attributes: statusAttributes)

        let labelSize = drawCentered(Self.networkLabel, x: MenuStyle.leftInset, attributes: [
            .font: MenuStyle.boldFont, .foregroundColor: NSColor.white, .shadow: shadow,
        ])

        var networkAttributes: [NSAttributedString.Key: Any] = [
            .font: MenuStyle.font, .foregroundColor: NSColor.white, .shadow: shadow,
        ]
        switch networkStyle {
        case .value:
            break
        case .missing:
            networkAttributes[.foregroundColor] = NSColor.white.withAlphaComponent(0.7)
        case .action:
            networkAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        drawCentered(network, x: MenuStyle.leftInset + labelSize.width + 4, attributes: networkAttributes)
    }

    override func mouseUp(with event: NSEvent) {
        guard let onClick else { return }
        enclosingMenuItem?.menu?.cancelTracking()
        onClick()
    }
}
