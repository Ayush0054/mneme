import Carbon
import Foundation

enum ShortcutAction: UInt32, CaseIterable, Identifiable, Hashable {
    case open = 1, next = 2, smart = 3
    var id: UInt32 { rawValue }
    var title: String {
        switch self {
        case .open: return "Open Mneme"
        case .next: return "Paste next in order"
        case .smart: return "Smart Paste"
        }
    }
}

enum Shortcut: String, Codable, CaseIterable, Identifiable, Hashable {
    case optionV, shiftOptionV, optionSpace, controlOptionV, controlOptionSpace
    case shiftCommandV, optionCommandV, shiftOptionCommandV

    var id: String { rawValue }
    var label: String {
        switch self {
        case .optionV: return "⌥V"
        case .shiftOptionV: return "⇧⌥V"
        case .optionSpace: return "⌥Space"
        case .controlOptionV: return "⌃⌥V"
        case .controlOptionSpace: return "⌃⌥Space"
        case .shiftCommandV: return "⇧⌘V"
        case .optionCommandV: return "⌥⌘V"
        case .shiftOptionCommandV: return "⇧⌥⌘V"
        }
    }
    var keyCode: UInt32 {
        switch self {
        case .optionSpace, .controlOptionSpace: return UInt32(kVK_Space)
        default: return UInt32(kVK_ANSI_V)
        }
    }
    var modifiers: UInt32 {
        switch self {
        case .optionV, .optionSpace: return UInt32(optionKey)
        case .shiftOptionV: return UInt32(shiftKey | optionKey)
        case .controlOptionV, .controlOptionSpace: return UInt32(controlKey | optionKey)
        case .shiftCommandV: return UInt32(shiftKey | cmdKey)
        case .optionCommandV: return UInt32(optionKey | cmdKey)
        case .shiftOptionCommandV: return UInt32(shiftKey | optionKey | cmdKey)
        }
    }
}

struct ShortcutSettings: Codable {
    var open: Shortcut = .optionSpace
    var next: Shortcut = .shiftOptionV
    var smart: Shortcut = .optionV

    subscript(_ action: ShortcutAction) -> Shortcut {
        get {
            switch action {
            case .open: return open
            case .next: return next
            case .smart: return smart
            }
        }
        set {
            switch action {
            case .open: open = newValue
            case .next: next = newValue
            case .smart: smart = newValue
            }
        }
    }

    static func load() -> ShortcutSettings {
        guard let data = UserDefaults.standard.data(forKey: "keyboardShortcuts"),
              let settings = try? JSONDecoder().decode(Self.self, from: data),
              Set(ShortcutAction.allCases.map { settings[$0] }).count == ShortcutAction.allCases.count
        else { return Self() }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "keyboardShortcuts")
    }
}
