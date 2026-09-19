import AppKit
import SwiftUI

@main
enum MnemeApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = ClipboardModel()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var hotKeys: HotKeys?

    func applicationDidFinishLaunching(_ notification: Notification) {
        BookFonts.register()
        NSApp.setActivationPolicy(.accessory)
        configureEditMenu()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.image = MnemeMenuIcon.make()
            button.toolTip = "Mneme · \(model.shortcuts.open.label)"
            button.target = self
            button.action = #selector(togglePanel)
        }
        popover.behavior = .transient
        let panelHeight = min(BookTheme.height, max(520, (NSScreen.main?.visibleFrame.height ?? 790) - 70))
        popover.contentSize = NSSize(width: BookTheme.width, height: panelHeight)
        popover.contentViewController = NSHostingController(rootView: ClipboardPanel(model: model, height: panelHeight))
        model.showPanel = { [weak self] in self?.openPanel(captureTarget: false) }
        model.hidePanel = { [weak self] in self?.popover.performClose(nil) }
        model.start()
        hotKeys = HotKeys(settings: model.shortcuts) { [weak self] action in
            guard let self else { return }
            switch action {
            case .open: self.togglePanel()
            case .next: self.model.pasteNext(fromPanel: self.popover.isShown)
            case .smart: self.model.smartPaste(fromPanel: self.popover.isShown)
            }
        }
        model.changeShortcut = { [weak self] action, shortcut in
            guard let self, let hotKeys = self.hotKeys else { return }
            self.model.shortcutError = hotKeys.change(action, to: shortcut)
            self.syncShortcuts()
        }
        model.resetShortcuts = { [weak self] in
            guard let self, let hotKeys = self.hotKeys else { return }
            self.model.shortcutError = hotKeys.restoreDefaults()
            self.syncShortcuts()
        }
        syncShortcuts()
        openPanel(captureTarget: true)
    }

    func applicationWillTerminate(_ notification: Notification) { model.stop() }

    private func syncShortcuts() {
        guard let hotKeys else { return }
        model.shortcuts = hotKeys.settings
        model.unavailableShortcuts = hotKeys.unavailable
        statusItem?.button?.toolTip = "Mneme · \(model.shortcuts.open.label)"
    }

    @objc private func togglePanel() {
        if popover.isShown { popover.performClose(nil) }
        else { openPanel(captureTarget: true) }
    }

    @objc private func openSettings() {
        model.section = .settings
        openPanel(captureTarget: !popover.isShown)
    }

    private func openPanel(captureTarget: Bool) {
        guard let button = statusItem?.button else { return }
        if captureTarget {
            model.savedTarget = try? TargetAccess.capture()
            model.targetLabel = model.savedTarget?.context.displayName ?? ""
        }
        model.accessibilityEnabled = TargetAccess.isTrusted
        do { try model.refreshAPIKey() }
        catch { model.status = error.localizedDescription }
        if !popover.isShown { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
        NSApp.activate()
        popover.contentViewController?.view.window?.makeKey()
    }

    private func configureEditMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let settingsItem = appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Mneme", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        menu.addItem(editItem)
        NSApp.mainMenu = menu
    }
}
