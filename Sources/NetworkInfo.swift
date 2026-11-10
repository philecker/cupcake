import Foundation
import SystemConfiguration
import CoreWLAN

/// Reads network details from the system. Everything here is a quick, synchronous lookup
/// except `fetchExternalIP`, which goes out to the internet.
enum NetworkInfo {

    // MARK: Interfaces

    /// IPv4 address of every interface that's up, keyed by BSD name (en0, utun3, …). Loopback is skipped.
    static func ipv4Addresses() -> [String: String] {
        var addresses: [String: String] = [:]
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return addresses }
        defer { freeifaddrs(list) }

        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = entry.pointee
            guard let address = interface.ifa_addr, address.pointee.sa_family == UInt8(AF_INET) else { continue }

            let flags = Int32(interface.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(address, socklen_t(address.pointee.sa_len),
                                     &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            guard result == 0 else { continue }

            let name = String(cString: interface.ifa_name)
            if addresses[name] == nil {
                addresses[name] = String(cString: host)
            }
        }
        return addresses
    }

    /// BSD names of the Wi-Fi and wired Ethernet interfaces, as macOS classifies them.
    static func interfaceNames() -> (wifi: [String], ethernet: [String]) {
        var wifi: [String] = []
        var ethernet: [String] = []

        for interface in allInterfaces() {
            guard let bsdName = SCNetworkInterfaceGetBSDName(interface),
                  let type = SCNetworkInterfaceGetInterfaceType(interface) else { continue }

            let kind = type as String
            if kind == kSCNetworkInterfaceTypeIEEE80211 as String {
                wifi.append(bsdName as String)
            } else if kind == kSCNetworkInterfaceTypeEthernet as String {
                ethernet.append(bsdName as String)
            }
        }
        return (wifi, ethernet)
    }

    private static func allInterfaces() -> [SCNetworkInterface] {
        SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
    }

    // MARK: Routing and DNS

    /// The interface macOS is sending traffic through. With Wi-Fi and Ethernet both connected,
    /// this is whichever is higher in System Settings › Network (normally Ethernet).
    static func primaryInterface() -> String? {
        globalIPv4()?["PrimaryInterface"] as? String
    }

    /// The default gateway, i.e. the router.
    static func gatewayIP() -> String? {
        globalIPv4()?["Router"] as? String
    }

    /// DNS servers in use, IPv4 first, without duplicates.
    static func dnsServers() -> [String] {
        guard let servers = globalDNS()?["ServerAddresses"] as? [String] else { return [] }

        var seen = Set<String>()
        let unique = servers.filter { seen.insert($0).inserted }
        let ipv4 = unique.filter { $0.contains(".") }
        let ipv6 = unique.filter { !$0.contains(".") }
        return ipv4 + ipv6
    }

    private static func globalIPv4() -> [String: Any]? {
        dynamicStoreValue("State:/Network/Global/IPv4")
    }

    private static func globalDNS() -> [String: Any]? {
        dynamicStoreValue("State:/Network/Global/DNS")
    }

    private static func dynamicStoreValue(_ key: String) -> [String: Any]? {
        guard let store = SCDynamicStoreCreate(nil, "Cupcake" as CFString, nil, nil) else { return nil }
        return SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any]
    }

    // MARK: Wi-Fi

    /// Name of the current Wi-Fi network. macOS only tells apps that have Location access.
    static func wifiNetworkName() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }

    // MARK: External IP

    private static let externalIPServices = [
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ifconfig.me/ip",
    ]

    /// Looks up the public IP, trying each service in turn. Calls back with nil if they all fail.
    static func fetchExternalIP(completion: @escaping @MainActor (String?) -> Void) {
        func tryService(at index: Int) {
            guard index < externalIPServices.count else {
                Task { @MainActor in completion(nil) }
                return
            }

            var request = URLRequest(url: URL(string: externalIPServices[index])!)
            request.timeoutInterval = 6
            request.cachePolicy = .reloadIgnoringLocalCacheData

            URLSession.shared.dataTask(with: request) { data, response, _ in
                let succeeded = (response as? HTTPURLResponse)?.statusCode == 200
                let ip = data
                    .flatMap { String(data: $0, encoding: .utf8) }?
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if succeeded, let ip, !ip.isEmpty, ip.count <= 45 {
                    Task { @MainActor in completion(ip) }
                } else {
                    tryService(at: index + 1)
                }
            }.resume()
        }

        tryService(at: 0)
    }
}
