import AppKit
import SwiftUI

// A filled next item above two waiting items, in a 32 × 96 coordinate space.
private enum MarkGeometry {
    static let next = CGPath(ellipseIn: CGRect(x: 4, y: 2, width: 24, height: 24), transform: nil)
    static let waiting: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 16, y: 26))
        path.addLine(to: CGPoint(x: 16, y: 34))
        path.addEllipse(in: CGRect(x: 4, y: 36, width: 24, height: 24))
        path.addEllipse(in: CGRect(x: 4, y: 70, width: 24, height: 24))
        return path
    }()

    static func fitted(_ path: CGPath, to rect: CGRect) -> CGPath {
        let scale = min(rect.width / 32, rect.height / 96)
        var transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                          tx: rect.midX - 16 * scale, ty: rect.midY - 48 * scale)
        return path.copy(using: &transform) ?? path
    }
}

struct MnemeMark: View {
    var height: CGFloat = 42

    var body: some View {
        let bounds = CGRect(x: 0, y: 0, width: height / 3, height: height)
        ZStack {
            Path(MarkGeometry.fitted(MarkGeometry.waiting, to: bounds))
                .stroke(BookTheme.ink, style: StrokeStyle(lineWidth: height / 24, lineCap: .round))
            Path(MarkGeometry.fitted(MarkGeometry.next, to: bounds))
                .fill(BookTheme.brass)
        }
        .frame(width: height / 3, height: height)
        .accessibilityHidden(true)
    }
}

enum MnemeMenuIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 20), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let bounds = CGRect(x: 5, y: 1, width: 8, height: 18)
            context.setStrokeColor(NSColor.black.cgColor)
            context.setFillColor(NSColor.black.cgColor)
            context.setLineWidth(1.15)
            context.setLineCap(.round)
            context.addPath(MarkGeometry.fitted(MarkGeometry.waiting, to: bounds))
            context.strokePath()
            context.addPath(MarkGeometry.fitted(MarkGeometry.next, to: bounds))
            context.fillPath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Mneme clipboard"
        return image
    }
}
