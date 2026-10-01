# Tock

Tock is a macOS menu-bar app that plays a sound every time you click the mouse,
and optionally a soft tick as you scroll and a sound as you type.
The sounds are synthesized in code: 12 of them, in three families (Desk, Analog,
Toybox). It is free and open source.

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
