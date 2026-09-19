import AppKit
import ApplicationServices

struct PasteTarget {
    let app: NSRunningApplication
    let element: AXUIElement
    let context: FieldContext
}

@MainActor
enum TargetAccess {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        // TCC needs a real app identity; the packaging script supplies one.
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func capture() throws -> PasteTarget {
        guard isTrusted else {
            throw MnemeError.message("Enable Mneme in System Settings → Privacy & Security → Accessibility.")
        }
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            throw MnemeError.message("Focus a text field in another app, then use a paste shortcut.")
        }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.25)
        guard let element = elementAttribute(root, kAXFocusedUIElementAttribute) else {
            throw MnemeError.message("This app does not expose its focused field. Use Copy, then ⌘V.")
        }
        let role = stringAttribute(element, kAXRoleAttribute)
        let subrole = stringAttribute(element, kAXSubroleAttribute)
        guard subrole != "AXSecureTextField" else {
            throw MnemeError.message("Mneme does not paste into password fields.")
        }
        guard ["AXTextField", "AXTextArea", "AXComboBox"].contains(role) else {
            throw MnemeError.message("Focus an editable text field. Use Copy and ⌘V for unsupported editors.")
        }
        if let enabled = attribute(element, kAXEnabledAttribute) as? Bool, !enabled {
            throw MnemeError.message("The selected field is disabled.")
        }
        var labels = [stringAttribute(element, kAXTitleAttribute), stringAttribute(element, kAXDescriptionAttribute)]
        if let title = elementAttribute(element, kAXTitleUIElementAttribute) {
            labels.append(stringAttribute(title, kAXValueAttribute))
            labels.append(stringAttribute(title, kAXTitleAttribute))
        }
        let label = labels.filter { !$0.isEmpty }.joined(separator: " · ")
        let context = FieldContext(
            app: (app.localizedName ?? "Application").prefixScalars(300), role: role,
            label: label.prefixScalars(300),
            placeholder: stringAttribute(element, "AXPlaceholderValue").prefixScalars(300),
            help: stringAttribute(element, kAXHelpAttribute).prefixScalars(300)
        )
        return PasteTarget(app: app, element: element, context: context)
    }

    static func isStillFocused(_ target: PasteTarget) -> Bool {
        guard let current = try? capture(),
              current.app.processIdentifier == target.app.processIdentifier else { return false }
        return CFEqual(current.element, target.element) && current.context == target.context
    }

    static func paste(_ text: String, into target: PasteTarget, writeClipboard: (String) -> Bool) throws {
        guard isStillFocused(target) else {
            throw MnemeError.message("The focused field changed. Nothing was pasted; try again in the intended field.")
        }
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            throw MnemeError.message("Could not create the paste keystroke.")
        }
        guard writeClipboard(text) else { throw MnemeError.message("Could not write to the clipboard.") }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(target.app.processIdentifier)
        up.postToPid(target.app.processIdentifier)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func stringAttribute(_ element: AXUIElement, _ name: String) -> String {
        attribute(element, name) as? String ?? ""
    }

    private static func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
