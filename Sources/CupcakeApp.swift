// Cupcake: a menu bar app that shows your IP addresses. Click one to copy it.

import AppKit

@main
enum CupcakeApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
        withExtendedLifetime(delegate) { app.run() }
    }
}
