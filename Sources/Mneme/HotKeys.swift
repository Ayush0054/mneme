import Carbon

final class HotKeys {
    private struct Registration {
        let reference: EventHotKeyRef
        let id: UInt32
    }
    private var references: [ShortcutAction: Registration] = [:]
    private var nextRegistrationID: UInt32 = 1
    private var handler: EventHandlerRef?
    private let onPress: @MainActor (ShortcutAction) -> Void
    private(set) var settings: ShortcutSettings
    private(set) var unavailable: [ShortcutAction: String] = [:]

    init(settings: ShortcutSettings, onPress: @escaping @MainActor (ShortcutAction) -> Void) {
        self.settings = settings
        self.onPress = onPress
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                          nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.signature == 0x4D4E454D else { return OSStatus(eventNotHandledErr) }
            let center = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            let id = identifier.id
            Task { @MainActor in
                // Discard events queued for a shortcut that has since been replaced.
                guard let action = center.references.first(where: { $0.value.id == id })?.key else { return }
                center.onPress(action)
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else {
            for action in ShortcutAction.allCases { unavailable[action] = "Keyboard shortcuts could not start. Relaunch Mneme." }
            return
        }
        registerAll()
    }

    /// Register the replacement first so a conflict cannot remove the working shortcut.
    func change(_ action: ShortcutAction, to shortcut: Shortcut) -> String? {
        guard handler != nil else { return "Keyboard shortcuts could not start. Relaunch Mneme." }
        if let other = ShortcutAction.allCases.first(where: { $0 != action && settings[$0] == shortcut }) {
            return "\(shortcut.label) is assigned to \(other.title). Choose another shortcut."
        }
        if settings[action] == shortcut && references[action] != nil { return nil }
        guard let replacement = register(shortcut: shortcut) else {
            return "\(shortcut.label) is unavailable. Another app or macOS may be using it. Your previous shortcut was kept."
        }
        if let previous = references[action] { UnregisterEventHotKey(previous.reference) }
        references[action] = replacement
        settings[action] = shortcut
        unavailable.removeValue(forKey: action)
        settings.save()
        return nil
    }

    func restoreDefaults() -> String? {
        guard handler != nil else { return "Keyboard shortcuts could not start. Relaunch Mneme." }
        let previous = settings
        unregisterAll()
        settings = ShortcutSettings()
        registerAll()
        if !unavailable.isEmpty {
            // Swapped assignments require unregistering as a group. Roll back if any default fails.
            unregisterAll()
            settings = previous
            registerAll()
            return "One or more default shortcuts are unavailable. Previous settings were restored."
        }
        settings.save()
        return nil
    }

    private func register(shortcut: Shortcut) -> Registration? {
        var reference: EventHotKeyRef?
        let id = nextRegistrationID
        nextRegistrationID &+= 1
        let identifier = EventHotKeyID(signature: 0x4D4E454D, id: id)
        let result = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, identifier,
                                        GetApplicationEventTarget(), 0, &reference)
        guard result == noErr, let reference else { return nil }
        return Registration(reference: reference, id: id)
    }

    private func registerAll() {
        unavailable.removeAll()
        for action in ShortcutAction.allCases {
            if let reference = register(shortcut: settings[action]) { references[action] = reference }
            else { unavailable[action] = "\(settings[action].label) is unavailable. Choose another shortcut below." }
        }
    }

    private func unregisterAll() {
        for registration in references.values { UnregisterEventHotKey(registration.reference) }
        references.removeAll()
    }

    deinit {
        unregisterAll()
        if let handler { RemoveEventHandler(handler) }
    }
}
