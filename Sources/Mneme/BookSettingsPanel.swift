import SwiftUI

struct BookSettingsPanel: View {
    @Bindable var model: ClipboardModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                smartPaste
                BookRule()
                localHistory
                BookRule()
                shortcuts
                Text("Mneme · memory").font(BookFonts.serif(20, italic: true))
                    .foregroundStyle(BookTheme.muted).frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .padding(.horizontal, BookTheme.inset).padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
        .font(BookFonts.sans(12))
    }

    private var smartPaste: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookSectionHeading(title: "Smart Paste")
            note("When you invoke Smart Paste, Mneme finds values in the newest 12 copies. Up to 60 values (1,200 characters each), their source labels and app names, and the destination field’s label, placeholder, and help text are sent to TypeSafe AI.")
            Toggle("Enable TypeSafe Smart Paste", isOn: $model.cloudEnabled)
                .toggleStyle(.switch).controlSize(.small)
            HStack(spacing: 8) {
                SecureField(model.hasAPIKey ? "Replace saved API key" : "TypeSafe API key", text: $model.apiKeyDraft)
                    .textFieldStyle(.plain).padding(11).bookGlass(radius: 8)
                    .accessibilityLabel("TypeSafe API key")
                Button("Save") { model.saveKey() }
                    .buttonStyle(BookButtonStyle()).disabled(model.apiKeyDraft.isEmpty)
            }
            HStack {
                note(model.keyFromDotEnv ? "Using TYPESAFE_API_KEY from .env" :
                        (model.hasAPIKey ? "Key saved in macOS Keychain" : "No API key configured"))
                Spacer(minLength: 8)
                if model.hasAPIKey && !model.keyFromDotEnv {
                    Button("Remove key") { model.deleteKey() }
                        .font(BookFonts.sans(11)).buttonStyle(.borderless)
                }
            }
            note("You can also set TYPESAFE_API_KEY in the project’s .env file. It takes precedence and reloads when you invoke Smart Paste.")
            note("Copy a contact block once; Smart Paste inserts the matching name, email, or company into each focused field without opening Mneme. The original copy stays available. If it cannot paste, you hear an error sound. Open Mneme yourself to read the reason or choose an item.")
        }
    }

    private var localHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookSectionHeading(title: "Local memory")
            Toggle("Pause clipboard capture", isOn: $model.isPaused)
                .toggleStyle(.switch).controlSize(.small)
            Toggle("Remember history after quitting", isOn: $model.rememberHistory)
                .toggleStyle(.switch).controlSize(.small)
            note("Off by default. When enabled, the latest 200 text copies are saved to a local, unencrypted file readable by your Mac account. The queue resets when you quit.")
            Text("Exclude apps by bundle identifier").font(BookFonts.sans(11, weight: .medium))
            TextField("com.example.app, com.example.other", text: $model.excludedApps)
                .textFieldStyle(.plain).padding(11).bookGlass(radius: 8)
                .accessibilityLabel("Excluded application bundle identifiers")
            note("Known password apps and clipboard items marked concealed or transient are skipped. Secret detection is best-effort; pause capture for other sensitive content.")
            Button("Clear history and queue", role: .destructive) { model.clearAll() }
                .font(BookFonts.sans(11)).buttonStyle(.borderless)
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookSectionHeading(title: "Shortcuts")
            note("Smart Paste matches the focused field. Paste next follows copy order. Choose a combination for each action.")
            VStack(spacing: 12) {
                shortcut(.smart)
                shortcut(.next)
                shortcut(.open)
            }
            .padding(14).bookGlass()
            if let error = model.shortcutError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(BookFonts.sans(11)).foregroundStyle(BookTheme.ink)
            }
            Button("Restore default shortcuts") { model.resetShortcuts?() }
                .font(BookFonts.sans(11)).buttonStyle(.borderless).disabled(model.isBusy)
            BookRule().padding(.vertical, 4)
            Button(model.accessibilityEnabled ? "Open Accessibility settings" : "Enable Accessibility") {
                model.grantAccessibility()
            }
            .buttonStyle(BookButtonStyle())
        }
    }

    private func shortcut(_ action: ShortcutAction) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Picker(action.title, selection: Binding(
                get: { model.shortcuts[action] },
                set: { model.changeShortcut?(action, $0) }
            )) {
                ForEach(Shortcut.allCases) { shortcut in Text(shortcut.label).tag(shortcut) }
            }
            .pickerStyle(.menu).disabled(model.isBusy)
            if let error = model.unavailableShortcuts[action] {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(BookFonts.sans(11)).foregroundStyle(BookTheme.ink)
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text).font(BookFonts.sans(11)).lineSpacing(3)
            .foregroundStyle(BookTheme.muted).fixedSize(horizontal: false, vertical: true)
    }
}
