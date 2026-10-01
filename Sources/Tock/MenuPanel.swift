import SwiftUI
import TockCore

struct MenuPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Click sounds", isOn: $model.settings.enabled)
                .toggleStyle(.switch)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            if !model.listening {
                StatusRow(
                    text: "Permission needed to hear clicks",
                    button: "Open Settings",
                    action: model.openInputMonitoringSettings)
            } else {
                if !model.audioRunning {
                    StatusRow(text: "Audio output unavailable", button: "Retry", action: model.refresh)
                }
                soundList
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                Slider(value: $model.settings.volume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
            }
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Volume")

            Toggle("Sound on release", isOn: $model.settings.releaseSoundEnabled)
            Toggle("Sound on scroll", isOn: $model.settings.scrollSoundEnabled)
            Toggle("Sound on key press", isOn: $model.settings.keySoundEnabled)
            if model.keyPermissionNeeded {
                StatusRow(
                    text: "Allow Tock in Input Monitoring, then quit and reopen Tock",
                    button: "Open Settings",
                    action: model.openInputMonitoringSettings)
            }
            Toggle(
                "Launch at login",
                isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
            if let error = model.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Quit Tock") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 260)
        .onAppear { model.refresh() }
    }

    private var soundList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SoundFamily.allCases, id: \.self) { family in
                Text(family.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                ForEach(SoundLibrary.sounds(in: family)) { sound in
                    SoundRow(sound: sound, selected: sound.id == model.settings.soundID) {
                        model.select(sound)
                    }
                }
            }
        }
    }
}

private struct SoundRow: View {
    let sound: Sound
    let selected: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(sound.name)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hovered ? Color.primary.opacity(0.1) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct StatusRow: View {
    let text: String
    let button: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(button, action: action)
                .controlSize(.small)
        }
    }
}
