# Cupcake

A tiny macOS menu bar app that shows your IP addresses. Click the cupcake, click an address, and it's on your clipboard.

![menu bar](Resources/cupcakeTemplate@2x.png)

## Features

- **Status row** at the top, filled with the status colour: green for Online (with Wi-Fi, Ethernet or Personal Hotspot), purple for Online · VPN, orange for Connected · No Internet, red for Offline. The cupcake dims while you're offline.
- **Network:** on the left of the status row: your Wi-Fi network name, or N/A on Ethernet (wired networks don't have a name). With both connected it follows whichever macOS is actually using, normally Ethernet (see [Wi-Fi network name](#wi-fi-network-name) for why it asks for Location access)
- **Gateway IP**: your router's address, the one you type to reach its admin page
- **DNS**: the DNS server your Mac is currently using
- **LAN IP** (wired Ethernet) and **Wi-Fi IP** for your local network
- **VPN IP**, always listed and greyed out when no VPN is connected
- **External IP**, your public address as the internet sees it
- Hovering a row highlights it in charcoal and shows a copy icon just left of the value; values are right-aligned. Click anywhere on a row to copy its value, and the cupcake's frosting fills in for a moment to confirm
- Always current without a Refresh button: local addresses are re-read every time the menu opens, and the external IP is re-checked when your network changes or when you open the menu and the last check is over a minute old. To force a check, press ⌘R while the menu is open.
- Right-click (or Control-click) the cupcake for **Launch at Login** and **Quit Cupcake**, keeping the main menu just your addresses
- Menu bar only: no Dock icon, no windows

## Install

Cupcake isn't distributed as a downloadable app. You build it yourself from this source in about a minute. Because the app is compiled on your own Mac, macOS opens it without any "unidentified developer" or "damaged app" warnings, and nobody needs an Apple developer account.

### Requirements

- macOS 13 Ventura or later, on Apple silicon or Intel
- Apple's Command Line Tools, a free download of about 1 GB

### 1. Install the Command Line Tools (one time)

Open **Terminal** (Applications → Utilities) and check whether you already have them:

```sh
swiftc --version
```

If that prints a version, skip to step 2. Otherwise run this and click **Install** in the window that appears:

```sh
xcode-select --install
```

### 2. Get the source

With Git:

```sh
git clone https://github.com/philecker/cupcake.git
cd cupcake
```

Or without Git: on the GitHub page, click **Code → Download ZIP**, unzip it, then in Terminal:

```sh
cd ~/Downloads/cupcake-main
```

### 3. Build and install

```sh
bash build.sh
rm -rf /Applications/Cupcake.app        # removes any previous version
mv Cupcake.app /Applications/
open /Applications/Cupcake.app
```

The cupcake appears in your menu bar. There's no Dock icon; that's by design. To start Cupcake automatically, right-click the cupcake and turn on **Launch at Login**.

> macOS ignores case in file names, so `cupcake.app` and `Cupcake.app` count as the same name. Always remove the old app before moving a new one into Applications. Otherwise the new build ends up inside the old one.

### Updating

Quit Cupcake (right-click the cupcake → **Quit Cupcake**), get the latest source (`git pull`, or download the ZIP again), and repeat step 3. Each build is signed only for your Mac, so after an update you may need to turn **Launch at Login** off and on again.

### Troubleshooting

- **`xcrun: error: invalid active developer path`**: the Command Line Tools are missing or broken. Run `xcode-select --install`.
- **The cupcake doesn't appear**: your menu bar may be full, especially on a MacBook with a notch. Quit a few other menu bar apps, or hold ⌘ and drag icons to rearrange them.
- **The build fails**: [open an issue](https://github.com/philecker/cupcake/issues) and paste the Terminal output.

### What `build.sh` does

It compiles the files in `Sources/` with `swiftc`, assembles `Cupcake.app`, builds the app icon from `Resources/AppIcon.png`, copies in the menu bar icon, and signs the bundle with an ad-hoc signature, which makes it valid only on your Mac. It doesn't use `sudo` or install anything outside the project folder. Read it before running it if you like; it's under 40 lines.

## Project layout

```
cupcake/
├── build.sh                  # builds Cupcake.app
├── Info.plist                # bundle metadata (menu-bar-only via LSUIElement)
├── Resources/
│   ├── AppIcon.png           # 1024px source for the Finder/Applications icon
│   ├── cupcakeTemplate.png   # menu bar icon (template image, 16pt)
│   ├── cupcakeTemplate@2x.png
│   ├── cupcakeFilledTemplate.png  # frosting filled in (spaced), shown briefly after copying
│   └── cupcakeFilledTemplate@2x.png
├── tools/
│   └── make-menubar-icon.py  # regenerates both menu bar icons from AppIcon.png
└── Sources/
    ├── CupcakeApp.swift      # entry point
    ├── AppDelegate.swift     # menu bar item, menus, refreshing, copying
    ├── MenuRows.swift        # the custom-drawn status and address rows
    ├── NetworkInfo.swift     # reads IPs, gateway, DNS, Wi-Fi name, external IP
    └── CupcakeIcon.swift     # menu bar icons
```

## How it works

| Address     | Source |
|-------------|--------|
| Active link | `PrimaryInterface` in `State:/Network/Global/IPv4` decides between Wi-Fi and Ethernet |
| Gateway IP  | `Router` in `State:/Network/Global/IPv4` (the default route) |
| Wi-Fi IP    | IPv4 address of the interface macOS classifies as Wi-Fi (via `SystemConfiguration`) |
| LAN IP      | IPv4 address of the first wired Ethernet interface |
| VPN IP      | IPv4 address on a `utun`, `ipsec` or `ppp` interface |
| Wi-Fi Network | `CoreWLAN`, once Location access is granted |
| DNS         | `State:/Network/Global/DNS` in the `SystemConfiguration` dynamic store |
| Status      | `NWPathMonitor`; "No Internet" means connected but every external IP lookup failed |
| External IP | HTTPS request to [ipify](https://www.ipify.org), falling back to icanhazip.com and ifconfig.me |

Network changes are detected with `NWPathMonitor` and debounced by 1.5 seconds. Opening the menu re-reads local addresses and, if the last external lookup is older than 60 seconds, starts a new one. The menu shows the last known value while that lookup runs.

## Wi-Fi network name

Since macOS 14, apps can read the Wi-Fi network name only if they have Location access. The first time Cupcake launches, macOS asks for that permission once, and after you click **Allow** the network name simply appears. Cupcake reads the network name and nothing else; it never requests or stores your location. If you click **Don't Allow**, the status row offers **Allow in Settings…** in place of the name, which opens Location Services in System Settings.

Each build is signed only for the Mac that built it, so macOS may ask again after you rebuild.

## Privacy

Local addresses, the gateway, DNS servers and the Wi-Fi network name never leave your Mac. To find your external IP, Cupcake sends a plain HTTPS request to the services listed above on launch, when your network changes, when you open the menu and the last check is over a minute old, and when you press ⌘R. Those services see your public IP address and the time of the request. Nothing else is sent, and Cupcake collects no analytics.

## Known limitations

- On machines with several Ethernet adapters or docks, the LAN IP shown is the first one found, which isn't necessarily the active one.
- IPv6 addresses aren't shown yet.
- The address rows can be clicked but not activated with Return, and VoiceOver support for them is incomplete.
- There's no prebuilt download. A ready-to-run `Cupcake.app` that others can double-click would need Developer ID signing and Apple notarization, so building from source is the supported install.

## Credits

Menu bar and app icons from [philecker/cupcake](https://github.com/philecker/cupcake).
