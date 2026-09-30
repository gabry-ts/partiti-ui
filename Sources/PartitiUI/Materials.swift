import AppKit
import SwiftUI

/// Neutral inks matching the system label colors, resolved per color scheme so that
/// offscreen snapshots and live views agree exactly.
public struct Ink: Sendable {
    /// Whether these inks are for the dark scheme.
    public let isDark: Bool

    public init(_ scheme: ColorScheme) { isDark = scheme == .dark }

    private func level(_ light: Double, _ dark: Double) -> Color {
        isDark ? Color(white: 1, opacity: dark) : Color(white: 0, opacity: light)
    }

    /// Titles and values.
    public var primary: Color { isDark ? Color(white: 0.96) : Color(white: 0.11) }
    /// Labels, subtitles and inactive symbols.
    public var secondary: Color { level(0.55, 0.60) }
    /// Placeholders and details.
    public var tertiary: Color { level(0.34, 0.38) }
    /// Disabled text and faint outlines.
    public var quaternary: Color { level(0.18, 0.20) }
    /// Row separators.
    public var hairline: Color { level(0.09, 0.10) }
    /// Neutral fills: tracks, inactive chips, hover.
    public var fill: Color { level(0.05, 0.07) }
    /// A stronger neutral fill: slider tracks, pressed and hovered rows.
    public var strongFill: Color { level(0.09, 0.12) }
    /// Success, tuned for each scheme like the system green.
    public var green: Color { isDark ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(red: 0.16, green: 0.66, blue: 0.29) }
    /// Warnings.
    public var orange: Color { isDark ? Color(red: 1.0, green: 0.62, blue: 0.04) : Color(red: 0.93, green: 0.52, blue: 0.0) }
    /// Errors and counters that need attention.
    public var red: Color { isDark ? Color(red: 1.0, green: 0.27, blue: 0.23) : Color(red: 0.92, green: 0.20, blue: 0.17) }
}

/// Reads the color scheme and hands the matching `Ink` to its content.
public struct Inked<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    private let content: (Ink) -> Content

    public init(@ViewBuilder _ content: @escaping (Ink) -> Content) { self.content = content }

    public var body: some View { content(Ink(scheme)) }
}

// MARK: - Surface

/// A painted card on the popover's glass: translucent fill, top sheen, hairline edge,
/// optional color wash. Painted rather than glass, because glass on glass muddies text.
struct SurfaceModifier: ViewModifier {
    var radius: CGFloat
    var tint: Color?
    var tintAmount: Double
    var elevated: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        let high = contrast == .increased
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content.background {
            ZStack {
                shape.fill(Color.white.opacity(dark ? 0.07 : 0.55))
                if let tint {
                    shape.fill(tint.opacity((dark ? 0.18 : 0.12) * tintAmount))
                }
                shape.fill(LinearGradient(
                    colors: [Color.white.opacity(dark ? 0.05 : 0.40), Color.white.opacity(0)],
                    startPoint: .top, endPoint: .bottom))
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(dark ? 0.16 : 0.90), Color.white.opacity(dark ? 0.03 : 0.30)],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
                shape.strokeBorder((tint ?? .black).opacity(high ? 0.35 : (dark ? 0.14 : 0.07)), lineWidth: high ? 1 : 0.5)
            }
            .shadow(color: .black.opacity(elevated ? (dark ? 0.20 : 0.05) : 0), radius: 4, y: 1.5)
        }
    }
}

public extension View {
    /// Paints a Partiti UI card behind the view. `tint` adds a color wash, scaled by `tintAmount`;
    /// `elevated` adds the soft card shadow.
    func puiSurface(radius: CGFloat = PUI.Radius.card, tint: Color? = nil, tintAmount: Double = 1, elevated: Bool = true) -> some View {
        modifier(SurfaceModifier(radius: radius, tint: tint, tintAmount: tintAmount, elevated: elevated))
    }
}

// MARK: - Glass

/// Glass for controls. On macOS 26 it is the system Liquid Glass; on macOS 14 and 15 a system
/// material with the painted edge and shadow on top; in `.painted` rendering the painted
/// stand-in alone, so offscreen snapshots match the running app.
/// An optional tint is applied as a wash, never a solid fill.
struct GlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    var tint: Color?
    @Environment(\.puiGlassRendering) private var rendering
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        switch rendering {
        case .live:
            if #available(macOS 26, *) {
                content
                    .glassEffect(glass, in: shape)
                    .overlay(shape.strokeBorder(Color.white.opacity(liveEdge), lineWidth: 0.5).allowsHitTesting(false))
            } else {
                content.background { materialGlass }
            }
        case .painted:
            content.background { paintedGlass(base: true) }
        }
    }

    @available(macOS 26, *)
    private var glass: Glass {
        if let tint { return Glass.regular.tint(tint.opacity(0.18)).interactive() }
        return Glass.regular.interactive()
    }

    /// The extra edge Liquid Glass gets in dark mode and with Increase Contrast.
    private var liveEdge: Double {
        contrast == .increased ? 0.35 : (scheme == .dark ? 0.12 : 0)
    }

    /// The fallback before macOS 26: a thin material, so the backdrop still shows through,
    /// under the painted layers without their base fill. Opaque with Reduce Transparency.
    private var materialGlass: some View {
        ZStack {
            if reduceTransparency {
                shape.fill(Color(nsColor: .windowBackgroundColor))
            } else {
                shape.fill(.thinMaterial)
            }
            paintedGlass(base: false)
        }
    }

    /// The painted glass: base fill, tint wash, top sheen, light and dark hairlines, shadow.
    private func paintedGlass(base: Bool) -> some View {
        let dark = scheme == .dark
        let high = contrast == .increased
        return ZStack {
            if base { shape.fill(dark ? Color.white.opacity(0.10) : Color.white.opacity(0.62)) }
            if let tint { shape.fill(tint.opacity(dark ? 0.26 : 0.16)) }
            shape.fill(LinearGradient(
                colors: [Color.white.opacity(dark ? 0.10 : 0.55), Color.white.opacity(0)],
                startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(
                LinearGradient(colors: [Color.white.opacity(dark ? 0.22 : 1.0), Color.white.opacity(dark ? 0.05 : 0.35)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: 0.75)
            shape.strokeBorder(Color.black.opacity(high ? 0.35 : (dark ? 0.30 : 0.07)), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(dark ? 0.25 : 0.08), radius: 3, y: 1)
    }
}

public extension View {
    /// Wraps the view in Partiti UI glass. For controls only, never content cards:
    /// glass on glass muddies text, so cards use `puiSurface` instead.
    func puiGlass(_ shape: some InsettableShape = Capsule(), tint: Color? = nil) -> some View {
        modifier(GlassModifier(shape: shape, tint: tint))
    }
}

// MARK: - Lines and highlights

/// A hairline between rows of a grouped card.
public struct Hairline: View {
    var leading: CGFloat
    @Environment(\.colorScheme) private var scheme

    public init(leading: CGFloat = 0) { self.leading = leading }

    public var body: some View {
        Rectangle()
            .fill(Ink(scheme).hairline)
            .frame(height: 0.5)
            .padding(.leading, leading)
    }
}

public extension View {
    /// The hover highlight: a neutral fill in a row-radius shape, shown while `on` is true.
    func puiHoverHighlight(_ on: Bool, radius: CGFloat = PUI.Radius.row) -> some View {
        modifier(HoverHighlightModifier(on: on, radius: radius))
    }
}

struct HoverHighlightModifier: ViewModifier {
    let on: Bool
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(on ? Ink(scheme).strongFill : .clear))
    }
}
