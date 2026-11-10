#!/bin/bash
# Builds Cupcake.app next to this script.
# Needs the Xcode Command Line Tools (`xcode-select --install`).
set -euo pipefail
cd "$(dirname "$0")"

APP="Cupcake.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling…"
swiftc -O -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macos13.0" \
  -framework AppKit -framework SystemConfiguration -framework Network -framework ServiceManagement \
  -framework CoreWLAN -framework CoreLocation \
  Sources/*.swift -o "$APP/Contents/MacOS/Cupcake"

cp Info.plist "$APP/Contents/Info.plist"

echo "Adding icons…"
cp Resources/cupcakeTemplate.png Resources/cupcakeTemplate@2x.png \
   Resources/cupcakeFilledTemplate.png Resources/cupcakeFilledTemplate@2x.png \
   "$APP/Contents/Resources/"

# Finder/Applications icon, built from the 1024px source
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z $size $size Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo "Done: $(pwd)/$APP"
echo "Tip: move it into /Applications, then right-click the cupcake to turn on Launch at Login."
