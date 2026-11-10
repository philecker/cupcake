import AppKit
import CoreLocation
import Network
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, CLLocationManagerDelegate {

    private enum Link { case wifi, ethernet, other }

    private enum ConnectionType: String {
        case wifi = "Wi-Fi"
        case hotspot = "Personal Hotspot"
        case ethernet = "Ethernet"
        case cellular = "Cellular"

        init?(_ path: NWPath) {
            guard path.status == .satisfied else { return nil }
            if path.usesInterfaceType(.wifi) {
                self = path.isExpensive ? .hotspot : .wifi
            } else if path.usesInterfaceType(.wiredEthernet) {
                self = .ethernet
            } else if path.usesInterfaceType(.cellular) {
                self = .cellular
            } else {
                return nil
            }
        }
    }

    /// Shown in place of any value that can't be loaded.
    private static let noValue = "———"
    /// How long a public IP lookup stays fresh before opening the menu checks again.
    private static let externalIPMaxAge: TimeInterval = 60

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()          // left click
    private let contextMenu = NSMenu()   // right click
    private let icon = CupcakeIcon.make()
    private let copiedIcon = CupcakeIcon.filled()

    private let locationManager = CLLocationManager()
    private let pathMonitor = NWPathMonitor()

    // Current network state
    private var isOnline = true
    private var connectionType: ConnectionType?
    private var activeLink: Link = .other
    private var wifiIP: String?
    private var lanIP: String?
    private var vpnIP: String?
    private var gatewayIP: String?
    private var dnsServers: [String] = []
    private var wifiNetworkName: String?

    // External IP lookup
    private var externalIP: String?
    private var isLoadingExternalIP = false
    private var externalIPRequestID = 0
    private var lastExternalIPCheck: Date?

    private var pendingRefresh: Task<Void, Never>?
    private var iconReset: Task<Void, Never>?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = icon
        statusItem.button?.toolTip = "Cupcake"

        // Left and right clicks open different menus, so handle the click ourselves
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])

        menu.delegate = self
        menu.autoenablesItems = false
        contextMenu.delegate = self
        contextMenu.autoenablesItems = false

        // The Wi-Fi network name needs Location access. Ask once at launch; macOS remembers the answer.
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            requestLocationAccess()
        }

        refreshAll()
        startMonitoringNetwork()
    }

    private func startMonitoringNetwork() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let type = ConnectionType(path)
            Task { @MainActor in self?.networkChanged(online: online, type: type) }
        }
        pathMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    // MARK: - Status item clicks

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseDown
            || (event?.type == .leftMouseDown && event?.modifierFlags.contains(.control) == true)

        if isRightClick {
            rebuildContextMenu()
        }
        // Attaching the menu just for this click lets the status item show it natively.
        // menuDidClose detaches it again.
        statusItem.menu = isRightClick ? contextMenu : menu
        sender.performClick(nil)
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === self.menu else { return }
        refreshLocal()

        // The public IP can change without anything changing on this Mac (e.g. the ISP gives
        // the router a new address), so re-check if the last lookup is getting old.
        let isStale = lastExternalIPCheck.map { Date().timeIntervalSince($0) > Self.externalIPMaxAge } ?? true
        if isStale && !isLoadingExternalIP {
            refreshExternalIP()
        }
        rebuildMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    // MARK: - Refreshing

    private func networkChanged(online: Bool, type: ConnectionType?) {
        isOnline = online
        connectionType = type
        statusItem.button?.appearsDisabled = !online
        rebuildMenu()
        scheduleRefresh()
    }

    /// Network changes tend to arrive in bursts, so wait for things to settle before refreshing.
    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            self?.refreshAll()
        }
    }

    private func refreshAll() {
        refreshLocal()
        refreshExternalIP()
        rebuildMenu()
    }

    private func refreshLocal() {
        let addresses = NetworkInfo.ipv4Addresses()
        let interfaces = NetworkInfo.interfaceNames()

        wifiIP = interfaces.wifi.lazy.compactMap { addresses[$0] }.first
        lanIP = interfaces.ethernet.lazy.compactMap { addresses[$0] }.first
        vpnIP = addresses
            .filter { $0.key.hasPrefix("utun") || $0.key.hasPrefix("ipsec") || $0.key.hasPrefix("ppp") }
            .sorted { $0.key < $1.key }
            .first?.value
        gatewayIP = NetworkInfo.gatewayIP()
        dnsServers = NetworkInfo.dnsServers()
        wifiNetworkName = (wifiIP != nil && hasLocationAccess) ? NetworkInfo.wifiNetworkName() : nil

        // Which link macOS is actually using. With both connected this is normally Ethernet.
        let primary = NetworkInfo.primaryInterface()
        if let primary, interfaces.ethernet.contains(primary) {
            activeLink = .ethernet
        } else if let primary, interfaces.wifi.contains(primary) {
            activeLink = .wifi
        } else if primary == nil && lanIP != nil {
            // Cable plugged in but no default route yet
            activeLink = .ethernet
        } else {
            activeLink = (primary == nil && wifiIP != nil) ? .wifi : .other
        }
    }

    private func refreshExternalIP() {
        externalIPRequestID += 1
        let requestID = externalIPRequestID

        guard isOnline else {
            isLoadingExternalIP = false
            externalIP = nil
            return
        }

        isLoadingExternalIP = true
        NetworkInfo.fetchExternalIP { [weak self] ip in
            // Ignore answers to lookups that have since been superseded
            guard let self, requestID == self.externalIPRequestID else { return }
            self.isLoadingExternalIP = false
            self.lastExternalIPCheck = Date()
            self.externalIP = ip
            self.rebuildMenu()
        }
    }

    // MARK: - Building the menus

    private func rebuildMenu() {
        menu.removeAllItems()

        menu.addItem(makeStatusItem())
        menu.addItem(.separator())

        addAddressRow("Gateway IP", gatewayIP)
        addAddressRow("DNS", dnsServers.first)
        addAddressRow("LAN IP", lanIP)
        addAddressRow("Wi-Fi IP", wifiIP)
        addAddressRow("VPN IP", vpnIP)
        addAddressRow("External IP", externalIP,
                      placeholder: (isOnline && isLoadingExternalIP) ? "Checking…" : Self.noValue)

        // No visible row, but ⌘R still forces a refresh while the menu is open
        let refresh = makeItem("Refresh", #selector(refreshPressed), key: "r")
        refresh.isHidden = true
        refresh.allowsKeyEquivalentWhenHidden = true
        menu.addItem(refresh)
    }

    private func rebuildContextMenu() {
        contextMenu.removeAllItems()

        let launchAtLogin = makeItem("Launch at Login", #selector(toggleLaunchAtLogin), key: "")
        launchAtLogin.state = SMAppService.mainApp.status == .enabled ? .on : .off
        contextMenu.addItem(launchAtLogin)
        contextMenu.addItem(.separator())
        contextMenu.addItem(makeItem("Quit Cupcake", #selector(quit), key: "q"))
    }

    private func makeItem(_ title: String, _ action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    /// Adds a row that copies its value when clicked, or shows a greyed-out placeholder if there's no value.
    private func addAddressRow(_ label: String, _ value: String?, placeholder: String? = nil) {
        let item = NSMenuItem()
        item.isEnabled = value != nil
        item.toolTip = value != nil ? "Click to copy" : nil
        let text = value ?? placeholder ?? Self.noValue
        item.view = AddressRowView(label: label, value: text, enabled: value != nil) { [weak self] in
            if let value {
                self?.copyToClipboard(value)
            }
        }
        menu.addItem(item)
    }

    // MARK: - Status row

    private var connectionState: StatusRowView.State {
        if !isOnline {
            return .offline
        }
        // On a network, but every lookup failed (e.g. stuck behind a hotel sign-in page)
        if externalIP == nil && !isLoadingExternalIP && lastExternalIPCheck != nil {
            return .limited
        }
        return vpnIP != nil ? .vpn : .online
    }

    private func statusText(for state: StatusRowView.State) -> String {
        switch state {
        case .online:
            let link: String?
            switch activeLink {
            case .ethernet: link = ConnectionType.ethernet.rawValue
            case .wifi: link = connectionType == .hotspot ? ConnectionType.hotspot.rawValue : ConnectionType.wifi.rawValue
            case .other: link = connectionType?.rawValue
            }
            return ["Online", link].compactMap { $0 }.joined(separator: " · ")
        case .vpn:
            return "Online · VPN"
        case .limited:
            return "Connected · No Internet"
        case .offline:
            return "Offline"
        }
    }

    private func makeStatusItem() -> NSMenuItem {
        let state = connectionState
        let network = networkNameForStatusRow()

        let item = NSMenuItem()
        item.isEnabled = network.onClick != nil
        item.toolTip = network.onClick != nil ? "Turn on Location Services for Cupcake to show the network name" : nil
        item.view = StatusRowView(state: state, status: statusText(for: state),
                                  network: network.name, networkStyle: network.style, onClick: network.onClick)
        return item
    }

    /// What goes after "Network:" in the status row.
    private func networkNameForStatusRow() -> (name: String, style: StatusRowView.NetworkStyle, onClick: (() -> Void)?) {
        guard isOnline else {
            return (Self.noValue, .missing, nil)
        }
        if activeLink == .ethernet {
            // Wired networks don't have a name like Wi-Fi does
            return ("N/A", .missing, nil)
        }
        guard activeLink == .wifi, wifiIP != nil else {
            return (Self.noValue, .missing, nil)
        }

        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return ("Allow in Settings…", .action, { Self.openLocationSettings() })
        case .notDetermined:
            return (Self.noValue, .missing, nil)
        default:
            guard let name = wifiNetworkName else {
                return (Self.noValue, .missing, nil)
            }
            return (name, .value, nil)
        }
    }

    // MARK: - Location access

    private var hasLocationAccess: Bool {
        // macOS always reports a granted permission as .authorizedAlways (.authorizedWhenInUse is iOS-only)
        locationManager.authorizationStatus == .authorizedAlways
    }

    private func requestLocationAccess() {
        // A menu bar app has to be frontmost for the permission prompt to appear
        NSApp.activate(ignoringOtherApps: true)
        locationManager.requestWhenInUseAuthorization()
    }

    private static func openLocationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.refreshLocal()
            self.rebuildMenu()
        }
    }

    // MARK: - Actions

    @objc private func refreshPressed() {
        refreshAll()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert(error: error)
            alert.informativeText = "Move Cupcake.app into your Applications folder and try again.\n\n\(error.localizedDescription)"
            alert.runModal()
        }
        rebuildContextMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // Fill in the frosting for a moment to show it worked
        statusItem.button?.image = copiedIcon
        iconReset?.cancel()
        iconReset = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !Task.isCancelled else { return }
            self.statusItem.button?.image = self.icon
        }
    }
}
