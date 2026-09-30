import AppKit
import SwiftUI

/// The identity color of each app, taken from apps.partiti.dev.
/// It marks primary actions, selection and active state only; everything else is neutral.
public enum AppAccent: String, CaseIterable, Sendable {
    case tuuli, kaiku, kiito, mittari, kello

    /// The accent as a 0xRRGGBB value, the single source for `color` and `hex`.
    public var rgb: UInt32 {
        switch self {
        case .tuuli: 0x2F7BFF
        case .kaiku: 0xE8364F
        case .kiito: 0x22CBBB
        case .mittari: 0xF59E0B
        case .kello: 0x4C6EF5
        }
    }

    /// The canonical accent, in sRGB.
    public var color: Color { Color(rgb: rgb) }

    /// The accent as `#RRGGBB`, matching the site CSS.
    public var hex: String { "#" + String(format: "%06X", rgb) }

    /// The app's display name.
    public var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// Text and glyphs drawn in the accent: 18% deeper in light mode so they stay legible.
    public func legible(_ scheme: ColorScheme) -> Color {
        PUI.legible(color, scheme)
    }

    /// Whether white text reads on a solid accent fill. Bright accents take dark text.
    public var prefersDarkLabel: Bool { self == .kiito || self == .mittari }
}

public extension PUI {
    /// A color made a touch deeper in light mode, so it still reads as text on glass.
    static func legible(_ color: Color, _ scheme: ColorScheme) -> Color {
        scheme == .dark ? color : mix(color, with: .black, by: 0.18)
    }

    /// Blends `color` toward `other` by `fraction` (0...1).
    /// Uses `Color.mix` on macOS 15 and later, and an sRGB blend before that.
    static func mix(_ color: Color, with other: Color, by fraction: Double) -> Color {
        if #available(macOS 15, *) {
            return color.mix(with: other, by: fraction)
        }
        return blendSRGB(color, other, fraction)
    }

    /// The pre-macOS 15 blend: straight interpolation of sRGB components and opacity.
    internal static func blendSRGB(_ color: Color, _ other: Color, _ fraction: Double) -> Color {
        let t = min(max(fraction, 0), 1)
        guard let a = NSColor(color).usingColorSpace(.sRGB),
              let b = NSColor(other).usingColorSpace(.sRGB) else { return color }
        func lerp(_ x: CGFloat, _ y: CGFloat) -> Double { Double(x + (y - x) * t) }
        return Color(.sRGB,
                     red: lerp(a.redComponent, b.redComponent),
                     green: lerp(a.greenComponent, b.greenComponent),
                     blue: lerp(a.blueComponent, b.blueComponent),
                     opacity: lerp(a.alphaComponent, b.alphaComponent))
    }
}

/// Everything an app tells Partiti UI about itself, set once at the root.
/// It feeds the shared pieces that name the app, such as the About pane.
public struct PartitiBrand: Sendable {
    /// Which app this is; sets the name and the accent.
    public var accent: AppAccent
    /// One line under the name in About.
    public var tagline: String
    /// The sentence above the Coffee capsule in About.
    public var coffeeLine: String
    /// The app icon, drawn at 96 pt in About.
    public var icon: Image

    /// The app's display name.
    public var name: String { accent.name }

    public init(accent: AppAccent, tagline: String, coffeeLine: String, icon: Image) {
        self.accent = accent
        self.tagline = tagline
        self.coffeeLine = coffeeLine
        self.icon = icon
    }
}

// MARK: - Environment

extension EnvironmentValues {
    /// The current app accent, read by every Partiti UI component.
    @Entry public var puiAccent: AppAccent = .kello
    /// How glass is drawn. Running apps keep `.live`; offscreen snapshots use `.painted`.
    @Entry public var puiGlassRendering: GlassRendering = .live
}

/// How glass surfaces are produced.
public enum GlassRendering: Sendable {
    /// The real thing: Liquid Glass on macOS 26, a system material before that.
    case live
    /// A painted approximation that `ImageRenderer` can draw, for README and site images.
    /// System glass and AppKit-backed controls such as menus don't render offscreen,
    /// so in this mode components draw stand-ins for them.
    case painted
}

public extension View {
    /// Applies an app's identity once, at the root of a popover or window:
    /// sets the accent for Partiti UI components and the system tint for native controls.
    func puiAccent(_ accent: AppAccent) -> some View {
        environment(\.puiAccent, accent).tint(accent.color)
    }

    /// Chooses how glass is drawn below this view. Only offscreen renders need `.painted`.
    func puiGlassRendering(_ rendering: GlassRendering) -> some View {
        environment(\.puiGlassRendering, rendering)
    }
}
