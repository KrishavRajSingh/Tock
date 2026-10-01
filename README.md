# Tock

Tock is a macOS app that plays a sound every time you click the mouse,
and optionally a soft tick as you scroll and a sound as you type.
The sounds are synthesized in code: 16 of them, in four families (Desk, Analog,
Toybox, Mechanical). It is free and open source.

Opening Tock shows a small window for picking a sound and setting the volume.
Closing the window leaves Tock running; the same controls stay in the menu bar,
and clicking the Dock icon brings the window back.

Mouse and scroll sounds need no special permission. Keyboard sounds are off
until you turn them on, and need the Input Monitoring permission. Even then
Tock only notices that a key went down or up; it never reads which key.

## Requirements

- macOS 13 or later, Apple silicon or Intel.
- To build: Swift 5.9 or later (Xcode or the Command Line Tools).

## Build and run

```bash
scripts/bundle.sh
open build/Tock.app
```

The build is not signed with an Apple Developer ID. If macOS refuses to open a
copy you downloaded, open System Settings → Privacy & Security and choose
"Open Anyway". A copy you build yourself opens without that step.

To make a disk image that others can install from (open it, drag Tock to
Applications):

```bash
scripts/dmg.sh
```

The app icon is drawn by `scripts/icon.swift`; after changing it, run
`scripts/icon.sh` to rewrite `Resources/Tock.icns`.

The download page lives in `docs/index.html` and is served by GitHub Pages.

To run without making a bundle (launch at login is unavailable this way):

```bash
swift run Tock
```

## Tune the sounds

Every sound is a recipe in `Sources/TockCore/SoundLibrary.swift`: a few layers
of noise or tone, each with an envelope and an optional filter. To hear them
outside the app, write them all to WAV files:

```bash
swift run tock-render renders
open renders
```

## Tests

```bash
scripts/test.sh
```

Use the script rather than `swift test`: with the Command Line Tools alone, the
test framework is installed but not on the default search path.

## Licence

MIT. See `LICENSE`.
