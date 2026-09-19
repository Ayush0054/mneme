import AppKit
import CoreText
import SwiftUI

enum BookFonts {
    static func register() {
        guard let folder = Bundle.main.resourceURL?.appendingPathComponent("Fonts") else { return }
        for file in ["InstrumentSerif-Regular.ttf", "InstrumentSerif-Italic.ttf", "DMSans-Variable.ttf"] {
            CTFontManagerRegisterFontsForURL(folder.appendingPathComponent(file) as CFURL, .process, nil)
        }
    }

    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular", size: size)
    }

    static func sans(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .custom("DMSans-9ptRegular", size: size).weight(weight)
    }
}

enum BookTheme {
    static let width: CGFloat = 492
    static let height: CGFloat = 720
    static let inset: CGFloat = 26

    static let paper = adaptive(light: (0.970, 0.956, 0.927), dark: (0.125, 0.130, 0.123))
    static let ink = adaptive(light: (0.160, 0.180, 0.155), dark: (0.940, 0.925, 0.885))
    static let muted = adaptive(light: (0.400, 0.420, 0.375), dark: (0.670, 0.700, 0.630))
    static let accent = adaptive(light: (0.290, 0.390, 0.310), dark: (0.665, 0.780, 0.670))
    static let brass = adaptive(light: (0.655, 0.463, 0.200), dark: (0.820, 0.650, 0.365))
    static let rule = ink.opacity(0.13)

    private static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let rgb = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}

struct BookBackdrop: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if !reduceTransparency { FrostedWindow() }
            BookTheme.paper.opacity(reduceTransparency ? 1 : 0.78)
            if !reduceTransparency {
                LinearGradient(colors: [.white.opacity(colorScheme == .dark ? 0.05 : 0.38), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .overlay(alignment: .leading) {
            Rectangle().fill(BookTheme.rule.opacity(0.4)).frame(width: 1).padding(.leading, 12)
        }
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FrostedWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct BookGlass: ViewModifier {
    var radius: CGFloat
    var tint: Color
    var interactive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(BookTheme.paper, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(BookTheme.rule))
        } else {
            #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content.glassEffect(.regular.tint(tint).interactive(interactive),
                                    in: RoundedRectangle(cornerRadius: radius))
            } else {
                fallback(content)
            }
            #else
            fallback(content)
            #endif
        }
    }

    private func fallback(_ content: Content) -> some View {
        content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .background(tint, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(.white.opacity(0.30), lineWidth: 0.5))
    }
}

extension View {
    func bookGlass(radius: CGFloat = 12, tint: Color = .clear, interactive: Bool = false) -> some View {
        modifier(BookGlass(radius: radius, tint: tint, interactive: interactive))
    }
}

struct BookButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BookFonts.sans(12, weight: .medium))
            .foregroundStyle(prominent ? BookTheme.ink : BookTheme.muted)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(minHeight: 42)
            .bookGlass(tint: prominent ? BookTheme.accent.opacity(0.19) : .clear, interactive: true)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(prominent ? BookTheme.accent.opacity(0.30) : BookTheme.rule.opacity(0.6), lineWidth: 0.5))
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(enabled ? 1 : 0.42)
    }
}

struct BookRule: View {
    var body: some View { Rectangle().fill(BookTheme.rule).frame(height: 0.5).accessibilityHidden(true) }
}

struct BookKey: View {
    let text: String
    var body: some View {
        Text(text).font(BookFonts.sans(10, weight: .medium))
            .foregroundStyle(BookTheme.muted)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(BookTheme.ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(BookTheme.rule, lineWidth: 0.5))
    }
}

struct BookSectionHeading: View {
    let title: String
    var body: some View {
        Text(title).font(BookFonts.serif(30)).foregroundStyle(BookTheme.ink)
            .accessibilityAddTraits(.isHeader)
    }
}
