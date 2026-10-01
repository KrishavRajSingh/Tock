#!/bin/bash
# Packs build/Tock.app into build/Tock.dmg with a drag-to-Applications layout.
# Uses the app that is already built; run scripts/bundle.sh first for a fresh
# one. (Rebuilding changes the ad-hoc signature, which makes macOS forget any
# Input Monitoring grant, so this script never rebuilds an existing app.)
set -euo pipefail
cd "$(dirname "$0")/.."

app=build/Tock.app
dmg=build/Tock.dmg

[[ -d "$app" ]] || scripts/bundle.sh

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"

rm -f "$dmg"
hdiutil create -volname Tock -srcfolder "$stage" -format UDZO -quiet "$dmg"

echo "Built $dmg"
du -h "$dmg" | cut -f1
