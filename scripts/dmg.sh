#!/bin/bash
# Packs build/Tock.app into build/Tock.dmg: a window with Tock on the left, the
# Applications folder on the right, and a picture telling the user to drag.
# Uses the app that is already built; run scripts/bundle.sh first for a fresh
# one. (Rebuilding changes the ad-hoc signature, which makes macOS forget any
# Input Monitoring grant, so this script never rebuilds an existing app.)
set -euo pipefail
cd "$(dirname "$0")/.."

app=build/Tock.app
dmg=build/Tock.dmg

[[ -d "$app" ]] || scripts/bundle.sh

work=$(mktemp -d)
mount=""
cleanup() {
    [[ -n "$mount" ]] && hdiutil detach -quiet "$mount" 2>/dev/null || true
    rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/stage/.background"
cp -R "$app" "$work/stage/"
ln -s /Applications "$work/stage/Applications"
cp Resources/dmg-background.png "$work/stage/.background/background.png"

# A writable image first, so Finder can store the window layout in it.
hdiutil create -volname Tock -srcfolder "$work/stage" -fs HFS+ -format UDRW -quiet "$work/rw.dmg"
mount=$(hdiutil attach -readwrite -noverify -noautoopen "$work/rw.dmg" | awk -F'\t' '/\/Volumes\// {print $NF}')
disk=$(basename "$mount")

# Finder needs permission to be scripted; without it the image still works,
# it just opens as a plain window.
if ! osascript >/dev/null <<APPLESCRIPT
tell application "Finder"
    tell disk "$disk"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 740, 468}
        set opts to icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 96
        set text size of opts to 13
        set background picture of opts to file ".background:background.png"
        set position of item "Tock.app" of container window to {140, 150}
        set position of item "Applications" of container window to {400, 150}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
then
    echo "warning: could not set the window layout (Finder scripting not allowed); image will open as a plain window" >&2
fi

sync
hdiutil detach -quiet "$mount"
mount=""

rm -f "$dmg"
hdiutil convert "$work/rw.dmg" -format UDZO -quiet -o "$dmg"

echo "Built $dmg"
du -h "$dmg" | cut -f1
