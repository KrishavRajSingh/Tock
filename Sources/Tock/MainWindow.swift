import SwiftUI
import TockCore

struct MainView: View {
    @ObservedObject var model: AppModel

    /// Which sound the grid is choosing. Only matters while key sounds are on.
    @State private var chosenTarget = SoundTarget.mouse

    private var target: SoundTarget {
        model.settings.keySoundEnabled ? chosenTarget : .mouse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !model.listening {
                StatusRow(
                    text: "Permission needed to hear clicks",
                    button: "Open Settings",
                    action: model.openInputMonitoringSettings)
            } else {
                if !model.audioRunning {
                    StatusRow(text: "Audio output unavailable", button: "Retry", action: model.refresh)
                }
                soundGrid
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

            options
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(width: 340)
        .background(WindowMaterial().ignoresSafeArea())
        .onAppear { model.refresh() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tock")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text(model.settings.enabled ? "Sounding on every click" : "Silent")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Click sounds", isOn: $model.settings.enabled)
                .toggleStyle(.switch)
                .controlSize(.large)
                .labelsHidden()
        }
    }

    private var soundGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.settings.keySoundEnabled {
                Picker("Sound for", selection: $chosenTarget) {
                    Text("Mouse").tag(SoundTarget.mouse)
                    Text("Keyboard").tag(SoundTarget.keyboard)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            // There are more families than fit on a small screen, so they scroll.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(SoundFamily.allCases, id: \.self) { family in
                            Text(family.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible())], spacing: 6) {
                                ForEach(SoundLibrary.sounds(in: family)) { sound in
                                    SoundChip(sound: sound, selected: sound.id == model.settings.soundID(for: target)) {
                                        model.select(sound, for: target)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: 340)
                .onAppear { proxy.scrollTo(model.settings.soundID(for: target), anchor: .center) }
                .onChange(of: target) { proxy.scrollTo(model.settings.soundID(for: $0), anchor: .center) }
            }
        }
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: 8) {
            OptionRow("Sound on release", isOn: $model.settings.releaseSoundEnabled)
            OptionRow("Sound on scroll", isOn: $model.settings.scrollSoundEnabled)
            OptionRow("Sound on key press", isOn: $model.settings.keySoundEnabled)
            if model.keyPermissionNeeded {
                StatusRow(
                    text: "Allow Tock in Input Monitoring, then quit and reopen Tock",
                    button: "Open Settings",
                    action: model.requestKeyPermission)
            }
            OptionRow(
                "Launch at login",
                isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
            if let error = model.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SoundChip: View {
    let sound: Sound
    let selected: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(sound.name)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(fill))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var fill: Color {
        if selected { return .accentColor }
        return Color.primary.opacity(hovered ? 0.12 : 0.06)
    }
}

/// A switch with its label on the left and the switch at the right edge.
private struct OptionRow: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Toggle(title, isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }
}

/// The translucent backing that standard macOS windows use.
private struct WindowMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

@MainActor
final class MainWindow {
    private var window: NSWindow?

    func show(model: AppModel) {
        if window == nil {
            let controller = NSHostingController(rootView: MainView(model: model))
            // The content grows and shrinks (warnings, the mouse/keyboard
            // picker); let the window follow it.
            controller.sizingOptions = .preferredContentSize
            let window = NSWindow(contentViewController: controller)
            window.title = "Tock"
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
