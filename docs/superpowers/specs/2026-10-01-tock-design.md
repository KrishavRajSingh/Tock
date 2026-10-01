# Tock — design spec

Date: 2026-10-01
Status: approved

## Purpose

Tock is a free, open-source macOS menu-bar app that plays a synthesized sound
on every mouse click. It is an open-source alternative to the sound half of
Clacky (clacky.app, closed source, $4.99).

Goals, in priority order:

1. Ship a public open-source release that people actually install.
2. Leave a path to earning money later by selling signed, notarized builds.

The product's edge is the sounds themselves: their quality, variety and
character. Click capture and playback are commodity; an existing free tool
(kliq) already covers keyboard and mouse sounds.

"Tock" is a working name. Name availability has not been checked.

## Scope

In v1:

- Sound on left, right and middle mouse button press and release.
- Optional sound on scroll (off by default): one tick per wheel notch, or per
  40 points of trackpad travel, at most one tick every 30 ms.
- 12 synthesized sounds in 3 families.
- Optional sound on key press and release (off by default). Needs the Input
  Monitoring permission, asked for only when the user turns it on. Uses a
  listen-only `CGEventTap`; reads only the event type and the repeat flag,
  never the key code. Held-key repeats are silent.
- Menu-bar UI to enable/disable, pick a sound, set volume.
- First-launch welcome window; no permission is needed for mouse buttons.
- Launch at login.

Out of v1:

- Click ripples or any other visual overlay.
- Screen recorder, webcam bubble, vertical clips.
- User-supplied sound files.
- Click statistics, desktop pet.
- Payments, licence keys, auto-update.
- Code signing with a Developer ID and notarization.

## Decisions already made

| Decision | Choice | Reason |
|---|---|---|
| Platform | macOS 13 or later, Apple silicon and Intel | Matches Clacky; `MenuBarExtra` and `SMAppService` need 13. |
| Language and build | Swift, Swift Package Manager, no Xcode project | Toolchain is already installed (Swift 6.2.4, Command Line Tools). Native gives the lowest click-to-sound latency. An Xcode project can be added later without code changes. |
| Sound source | Synthesized in code | No licensing risk in a public repo, tiny binary, every sound is tunable. |
| Distribution | Free, unsigned (ad-hoc signed) build on GitHub | No upfront cost. Signed paid builds are a later decision that needs no code change. |
| Licence | MIT | |
| Location | `/Users/chirkoot/opensrc/tock`, its own git repository | Becomes a public repo; kept apart from the private research folder. |

## Architecture

One executable target (`Tock`) for the app shell and one library target
(`TockCore`) for everything that can be tested without audio hardware or
system permissions. A second small executable (`tock-render`) writes sounds to
WAV files for tuning.

```
Sources/
  TockCore/        Synth, SoundRecipe, SoundLibrary, Settings model
  Tock/            App entry, ClickMonitor, AudioPlayer, menu-bar UI, onboarding
  tock-render/     CLI: render every sound to .wav
Tests/
  TockCoreTests/
scripts/
  bundle.sh        wraps the built binary into Tock.app
```

### Components

**ClickMonitor** (app target)
Listens system-wide for left, right and middle button down and up events and
calls a handler with `(button, phase)`. It does nothing else: no audio, no
settings. It also reports whether it currently has permission to listen.
The capture API (`NSEvent` global monitor or a listen-only `CGEventTap`) is
chosen by the spike described under "Open question".

**SoundRecipe and Synth** (core)
A `SoundRecipe` is a plain value describing one sound: a list of layers (noise
burst, sine or triangle tone, optional resonant filter), each with an
amplitude envelope, plus overall duration and gain. `Synth.render(recipe,
sampleRate, pitchShift)` is a pure function returning an array of `Float`
samples in the range -1...1. Noise uses a seeded generator so the same input
always gives the same output.

**SoundLibrary** (core)
The catalogue: 12 named sounds in 3 families (working family names: Desk,
Analog, Toybox). Each sound has a press recipe and a release recipe. The
release recipe is shorter and quieter.

**AudioPlayer** (app target)
Owns one `AVAudioEngine` and a pool of 8 `AVAudioPlayerNode` voices used
round-robin. When the selected sound changes it asks `Synth` for buffers and
keeps them in memory. On a click it schedules the ready buffer on the next
voice. Nothing is synthesized at click time.

To avoid a mechanical feel, each sound is pre-rendered at 5 slightly different
pitches (within about ±3%) and one is picked at random per click.

**Settings** (core model, app-target persistence)
Stored in `UserDefaults`:

- `enabled` (default on)
- `soundID` (default: first sound in Desk)
- `volume` 0...1 (default 0.6)
- `releaseSoundEnabled` (default on)
- `scrollSoundEnabled` (default off)
- `keySoundEnabled` (default off)

Launch at login is read from and written to `SMAppService.mainApp`, not stored
separately, so the setting cannot drift from the system's state.

**Menu-bar UI** (app target)
A SwiftUI `MenuBarExtra` in window style, no Dock icon (`LSUIElement`).
Contents: enable toggle, sound list grouped by family (clicking a sound
selects it and plays it once), volume slider, release-sound toggle, launch at
login toggle, Quit. If permission is missing, the panel shows a "Permission
needed" row with a button instead of the sound list being silently dead.

**Onboarding** (app target)
Shown on first launch and whenever permission is missing. One window that
explains that Tock listens for mouse buttons and scrolling, and that keyboard
sounds are off until turned on and never read which key was pressed,
with a button that opens the relevant pane of System Settings.

### Data flow

1. Launch: load settings, render buffers for the selected sound, start the
   engine, start `ClickMonitor`.
2. Click: `ClickMonitor` handler → if enabled, `AudioPlayer.play(phase)` →
   buffer scheduled on the next voice.
3. Sound change: settings update → `AudioPlayer` re-renders buffers off the
   main thread, then swaps them in.

## Error handling

- **No permission:** the app keeps running, shows the permission row and the
  onboarding window, and re-checks when the app becomes active. No crash, no
  repeated system prompts.
- **Audio device change** (headphones plugged in, output switched): observe
  `AVAudioEngineConfigurationChange` and restart the engine.
- **Engine fails to start:** show an error row in the menu panel; clicks are
  ignored until the next successful start.
- **Unknown `soundID` in stored settings** (sound removed in an update): fall
  back to the default sound.

## Testing

Automated, on `TockCore`:

- `Synth` output has the expected sample count for the recipe's duration.
- No sample exceeds ±1.0 and none is NaN or infinite, for every sound in the
  library at every pitch variant.
- Same recipe and seed give identical output.
- Every sound starts and ends near silence (no audible pop).
- Every library sound has a unique ID and both a press and a release recipe.
- Settings defaults, and fallback for an unknown `soundID`.

Manual, because they need real hardware and permissions:

- Clicks in other apps produce sound; fast clicking overlaps without cut-offs.
- Permission flow on a clean machine state.
- Switching audio output while running.
- Listening review of all 12 sounds via `tock-render` output.

Whether `swift test` works with Command Line Tools alone (no Xcode) is
unverified. If it does not, tests use the Swift Testing framework shipped with
the toolchain, or run as assertions in a small test executable.

## Sound tuning workflow

The author of the synthesis code cannot hear the output. `tock-render` writes
every sound to a WAV file in a folder. The user listens and describes what is
wrong; recipe numbers are adjusted and the files re-rendered. The automated
tests guard against technical faults (clipping, pops) but cannot judge whether
a sound is pleasant.

## Click capture — settled by spike

Question: does listening for mouse button events system-wide need the Input
Monitoring permission, and does it differ between an `NSEvent` global monitor
and a listen-only `CGEventTap`?

Result (macOS 26.3.1, arm64): a throwaway app bundle with a fresh bundle ID
and no permissions was launched with `open`. `CGPreflightListenEventAccess()`
returned `false`. The `NSEvent` global monitor received every mouse button
event (15 of 15). The listen-only `CGEventTap` was created but stayed disabled
and received none.

Decision: `ClickMonitor` uses `NSEvent.addGlobalMonitorForEvents`. No
permission is needed for mouse buttons, so onboarding is a first-launch
welcome window. The "Permission needed" row and the System Settings button
remain only for the case where the monitor cannot be installed. Not verified
on macOS 13–15. The spike code was not kept.

## Known limitations

- Unsigned builds trigger a Gatekeeper warning on first open; users must
  approve the app in System Settings or build from source.
- macOS ties permission grants to the app's code signature. With ad-hoc
  signing, a grant may need to be re-approved after an update.
- Sound quality depends on iterative tuning by ear and is the main schedule
  risk.
