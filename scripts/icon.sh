#!/bin/bash
# Draws the app icon and writes Resources/Tock.icns. The result is checked in;
# run this only after changing scripts/icon.swift.
set -euo pipefail
cd "$(dirname "$0")/.."

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

swift scripts/icon.swift "$work/icon.png"

set=$work/Tock.iconset
mkdir "$set"
for size in 16 32 128 256 512; do
    sips -z $size $size "$work/icon.png" --out "$set/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$work/icon.png" --out "$set/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$set" -o Resources/Tock.icns

echo "Built Resources/Tock.icns"
