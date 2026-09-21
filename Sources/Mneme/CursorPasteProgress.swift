import AppKit
import SwiftUI

/// A click-through progress badge: showing it must never change the paste target.
@MainActor
final class CursorPasteProgress {
    private let panel: CursorProgressPanel
    private var tracking: Task<Void, Never>?

    init() {
        panel = CursorProgressPanel(contentRect: NSRect(x: 0, y: 0, width: 28, height: 28),
                                    styleMask: [.borderless, .nonactivatingPanel],
                                    backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.animationBehavior = .none
    }

    func setVisible(_ visible: Bool) {
        if !visible {
            tracking?.cancel()
            tracking = nil
            panel.orderOut(nil)
            // Remove the progress view too, so its animation stops while idle.
            panel.contentView = nil
            return
        }
        guard tracking == nil else { return }
        panel.contentView = NSHostingView(rootView: CursorSpinner())
        moveBesidePointer()
        panel.orderFrontRegardless()
        // Poll only during a paste; no event tap or Input Monitoring permission needed.
        tracking = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.moveBesidePointer()
                do { try await Task.sleep(for: .milliseconds(33)) }
                catch { return }
            }
        }
    }

    private func moveBesidePointer() {
        let pointer = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) }) else { return }
        let bounds = screen.visibleFrame.insetBy(dx: 4, dy: 4)
        let size = panel.frame.size
        var x = pointer.x + 16
        var y = pointer.y - size.height - 12
        if x + size.width > bounds.maxX { x = pointer.x - size.width - 16 }
        if y < bounds.minY { y = pointer.y + 12 }
        panel.setFrameOrigin(NSPoint(x: min(max(x, bounds.minX), bounds.maxX - size.width),
                                     y: min(max(y, bounds.minY), bounds.maxY - size.height)))
    }
}

private final class CursorProgressPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct CursorSpinner: View {
    var body: some View {
        ProgressView()
            .controlSize(.small)
            .tint(BookTheme.accent)
            .frame(width: 28, height: 28)
            .bookGlass(radius: 14, tint: BookTheme.accent.opacity(0.10))
            .allowsHitTesting(false)
            .accessibilityLabel("Pasting")
    }
}
