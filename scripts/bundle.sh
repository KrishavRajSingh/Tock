#!/bin/bash
# Builds build/Tock.app: a universal (arm64 + x86_64), ad-hoc signed bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

app=build/Tock.app

swift build -c release --arch arm64 --product Tock
swift build -c release --arch x86_64 --product Tock

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
lipo -create \
    .build/arm64-apple-macosx/release/Tock \
    .build/x86_64-apple-macosx/release/Tock \
    -output "$app/Contents/MacOS/Tock"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/Tock.icns "$app/Contents/Resources/Tock.icns"
codesign --force --sign - "$app"

echo "Built $app"
lipo -info "$app/Contents/MacOS/Tock"
