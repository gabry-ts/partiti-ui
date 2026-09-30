import SwiftUI

// MARK: - Round glass buttons

/// The symbol of an icon control: 11 pt medium, in the legible accent when active,
/// faded when disabled.
struct IconGlyph: View {
    let symbol: String
    let active: Bool
    let width: CGFloat
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let ink = Ink(scheme)
        Image(systemName: symbol)
            .font(.system(size: PUI.Control.smallSymbol, weight: .medium))
            .foregroundStyle(!isEnabled ? ink.quaternary : (active ? accent.legible(scheme) : ink.primary.opacity(0.78)))
            .frame(width: width, height: PUI.Control.small)
    }
}

/// A 22 pt round glass button with an 11 pt medium symbol. Active state is an accent wash.
public struct GlassCircleButton: View {
    let symbol: String
    var active: Bool
    var action: () -> Void
    @Environment(\.puiAccent) private var accent
    @Environment(\.isEnabled) private var isEnabled

    public init(_ symbol: String, active: Bool = false, action: @escaping () -> Void) {
        self.symbol = symbol
        self.active = active
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            IconGlyph(symbol: symbol, active: active, width: PUI.Control.small)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .puiGlass(Circle(), tint: active && isEnabled ? accent.color : nil)
    }
}

/// A borderless icon button, for use inside a `GlassCapsule` where the capsule is the glass.
public struct IconButton: View {
    let symbol: String
    var active: Bool
    var action: () -> Void

    public init(_ symbol: String, active: Bool = false, action: @escaping () -> Void) {
        self.symbol = symbol
        self.active = active
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            IconGlyph(symbol: symbol, active: active, width: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A borderless icon that opens a menu, the `IconButton` look for use inside a `GlassCapsule`.
/// Drawn as its symbol alone in `.painted` rendering, since menus don't render offscreen.
public struct IconMenu<Items: View>: View {
    let symbol: String
    var active: Bool
    let items: Items
    @Environment(\.puiGlassRendering) private var rendering

    /// `items` are the menu's content: buttons, toggles, pickers or submenus.
    public init(_ symbol: String, active: Bool = false, @ViewBuilder items: () -> Items) {
        self.symbol = symbol
        self.active = active
        self.items = items()
    }

    public var body: some View {
        switch rendering {
        case .live:
            Menu {
                items
            } label: {
                IconGlyph(symbol: symbol, active: active, width: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
        case .painted:
            IconGlyph(symbol: symbol, active: active, width: 24)
        }
    }
}

/// A glass capsule grouping icon buttons, as on the right of a popover toolbar.
public struct GlassCapsule<Content: View>: View {
    let content: Content

    public init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    public var body: some View {
        HStack(spacing: 0) { content }
            .padding(.horizontal, PUI.Space.xxs)
            .frame(height: PUI.Control.small)
            .puiGlass(Capsule())
    }
}

// MARK: - Segmented pill

/// Two to four options on glass. 22 pt in popovers, 28 pt in windows.
public struct SegmentedPill<Value: Hashable>: View {
    let options: [(value: Value, title: String)]
    @Binding var selection: Value
    var height: CGFloat
    var stretch: Bool
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    /// `stretch` spreads the segments over the available width.
    public init(_ options: [(value: Value, title: String)], selection: Binding<Value>,
                height: CGFloat = PUI.Control.small, stretch: Bool = false) {
        self.options = options
        self._selection = selection
        self.height = height
        self.stretch = stretch
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let on = option.value == selection
                Button { selection = option.value } label: {
                    Text(option.title)
                        .font(.system(size: height > PUI.Control.small ? 12 : 11, weight: on ? .semibold : .medium))
                        .foregroundStyle(on ? ink.primary : ink.secondary)
                        .padding(.horizontal, PUI.Space.m + 2)
                        .frame(maxWidth: .infinity)
                        .frame(height: height - 4)
                        .background {
                            if on {
                                Capsule().fill(scheme == .dark ? Color.white.opacity(0.16) : Color.white)
                                    .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.12), radius: 1.5, y: 0.5)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(PUI.Space.xxs)
        .fixedSize(horizontal: !stretch, vertical: false)
        .frame(maxWidth: stretch ? .infinity : nil)
        .puiGlass(Capsule())
    }
}

// MARK: - Buttons

/// The only solid fill in the system: the primary action, in the accent.
/// Bright accents get a dark label so it stays readable; `color` overrides the accent.
/// Disabled, it turns into a neutral fill with a faint label.
public struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat
    var fullWidth: Bool
    var color: Color?
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    public init(height: CGFloat = PUI.Control.large, fullWidth: Bool = true, color: Color? = nil) {
        self.height = height
        self.fullWidth = fullWidth
        self.color = color
    }

    public func makeBody(configuration: Configuration) -> some View {
        let ink = Ink(scheme)
        let fill = color ?? accent.color
        let labelColor: Color = !isEnabled ? ink.tertiary
            : ((color == nil && accent.prefersDarkLabel) ? Color.black.opacity(0.82) : .white)
        configuration.label
            .font(.system(size: height >= PUI.Control.large ? 13 : 12, weight: .semibold))
            .foregroundStyle(labelColor)
            .padding(.horizontal, PUI.Space.l)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .background {
                let shape = RoundedRectangle(cornerRadius: PUI.Radius.group, style: .continuous)
                if isEnabled {
                    ZStack {
                        shape.fill(fill)
                        shape.fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                        shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                    }
                    .shadow(color: fill.opacity(0.35), radius: 4, y: 2)
                } else {
                    shape.fill(ink.strongFill)
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// A neutral secondary button, 28 pt or 22 pt, sitting next to a primary one or in rows.
/// Disabled, its label fades and the button sinks into the background.
public struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat
    var fullWidth: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    public init(height: CGFloat = PUI.Control.regular, fullWidth: Bool = false) {
        self.height = height
        self.fullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let ink = Ink(scheme)
        let shape = RoundedRectangle(cornerRadius: height >= PUI.Control.regular ? PUI.Radius.row : 6, style: .continuous)
        configuration.label
            .font(.system(size: height >= PUI.Control.regular ? 12 : 11, weight: .medium))
            .foregroundStyle(isEnabled ? ink.primary : ink.tertiary)
            .padding(.horizontal, height >= PUI.Control.regular ? PUI.Space.l : PUI.Space.m)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .background {
                ZStack {
                    shape.fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.85))
                    shape.strokeBorder(Color.black.opacity(scheme == .dark ? 0.25 : 0.10), lineWidth: 0.5)
                    shape.inset(by: 0.5).strokeBorder(Color.white.opacity(scheme == .dark ? 0.08 : 0.6), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.06), radius: 1, y: 0.5)
                .opacity(isEnabled ? 1 : 0.5)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// The small primary capsule used to join a call.
public struct JoinButton: View {
    /// How big the capsule is.
    public enum Size: Sendable {
        /// 22 pt, on its own in a card.
        case regular
        /// 18 pt, over the details line of a row.
        case compact
    }

    var title: String
    var size: Size
    var action: () -> Void
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: String = "Join", size: Size = .regular, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }

    public var body: some View {
        let compact = size == .compact
        let ink = Ink(scheme)
        Button(action: action) {
            Label(title, systemImage: "video.fill")
                .labelStyle(TightLabelStyle(spacing: compact ? 3 : PUI.Space.xs))
                .font(.system(size: compact ? 10 : 11, weight: .semibold))
                .foregroundStyle(!isEnabled ? ink.tertiary : (accent.prefersDarkLabel ? Color.black.opacity(0.82) : .white))
                .padding(.horizontal, compact ? PUI.Space.s + 1 : PUI.Space.m + 2)
                .frame(height: compact ? 18 : PUI.Control.small)
                .background {
                    if isEnabled {
                        ZStack {
                            Capsule().fill(accent.color)
                            Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                        }
                        .shadow(color: accent.color.opacity(0.4), radius: 3, y: 1)
                    } else {
                        Capsule().fill(ink.strongFill)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The Buy Me a Coffee capsule: 34 pt, in that site's own yellow.
public struct CoffeeButton: View {
    var action: () -> Void

    public init(action: @escaping () -> Void) { self.action = action }

    public var body: some View {
        Button(action: action) {
            Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                .labelStyle(TightLabelStyle(spacing: PUI.Space.s))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.24, green: 0.16, blue: 0.05))
                .padding(.horizontal, PUI.Space.xl + 2)
                .frame(height: PUI.Control.large)
                .background {
                    ZStack {
                        Capsule().fill(PUI.coffee)
                        Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                        Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                    }
                    .shadow(color: Color(red: 0.8, green: 0.6, blue: 0).opacity(0.35), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
    }
}

/// A label with a controlled gap between icon and title.
public struct TightLabelStyle: LabelStyle {
    var spacing: CGFloat

    public init(spacing: CGFloat = PUI.Space.xs) { self.spacing = spacing }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Badge

/// A short uppercase badge. Tinted by default; solid for counters that need attention.
public struct Badge: View {
    /// How loud the badge is.
    public enum Style: Sendable {
        /// A light wash of the color with legible text.
        case tinted
        /// A solid fill with white text, for counters.
        case solid
        /// Gray, for annotations like "est.".
        case neutral
    }

    let text: String
    var color: Color?
    var style: Style
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ text: String, color: Color? = nil, style: Style = .tinted) {
        self.text = text
        self.color = color
        self.style = style
    }

    public var body: some View {
        let base = color ?? accent.color
        let ink = Ink(scheme)
        Text(text.uppercased())
            .font(PUI.Font.badge)
            .tracking(PUI.Font.badgeTracking)
            .monospacedDigit()
            .foregroundStyle(style == .solid ? .white : (style == .neutral ? ink.secondary : PUI.legible(base, scheme)))
            .padding(.horizontal, PUI.Space.s)
            .frame(height: 16)
            .background(Capsule().fill(style == .solid ? base : (style == .neutral ? ink.fill : base.opacity(scheme == .dark ? 0.22 : 0.13))))
    }
}

// MARK: - Toggle, slider, pop-up

/// The macOS switch, drawn in SwiftUI so it takes the app accent and renders everywhere,
/// including offscreen snapshots where the AppKit switch does not. Disabled, the switch fades.
public struct PUISwitchStyle: ToggleStyle {
    var mini: Bool
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    /// `mini` is the smaller switch for popover rows.
    public init(mini: Bool = false) { self.mini = mini }

    public func makeBody(configuration: Configuration) -> some View {
        let w: CGFloat = mini ? 26 : 32
        let h: CGFloat = mini ? 15 : 18
        let on = configuration.isOn
        HStack(spacing: PUI.Space.m) {
            configuration.label
            Button {
                withAnimation(PUI.Motion.spring(reduceMotion: reduceMotion)) { configuration.isOn.toggle() }
            } label: {
                ZStack(alignment: on ? .trailing : .leading) {
                    Capsule()
                        .fill(on ? accent.color : (scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.10)))
                        .overlay(Capsule().strokeBorder(Color.black.opacity(on ? 0.06 : (scheme == .dark ? 0.2 : 0.06)), lineWidth: 0.5))
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                        .padding(1.5)
                }
                .frame(width: w, height: h)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityValue(on ? Text("On") : Text("Off"))
        }
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// A horizontal slider drawn in SwiftUI: accent fill, neutral track, white knob.
/// `ticks` draws that many evenly spaced marks under the track.
/// Disabled, the fill turns neutral, the slider fades and ignores drags.
public struct PUISlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var ticks: Int
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, ticks: Int = 0) {
        self._value = value
        self.range = range
        self.ticks = ticks
    }

    public var body: some View {
        let ink = Ink(scheme)
        GeometryReader { geo in
            let knob: CGFloat = 16
            let f = CGFloat(fraction)
            let x = max(geo.size.width - knob, 0) * f
            ZStack(alignment: .leading) {
                Capsule().fill(ink.strongFill).frame(height: 4)
                Capsule().fill(isEnabled ? accent.color : ink.tertiary).frame(width: x + knob / 2, height: 4)
                if ticks > 1 {
                    HStack(spacing: 0) {
                        ForEach(0..<ticks, id: \.self) { i in
                            Rectangle().fill(ink.tertiary).frame(width: 1, height: 4)
                            if i < ticks - 1 { Spacer(minLength: 0) }
                        }
                    }
                    .padding(.horizontal, knob / 2)
                    .offset(y: 8)
                }
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.28), radius: 1.5, y: 0.5)
                    .frame(width: knob, height: knob)
                    .offset(x: x)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                guard isEnabled else { return }
                let track = max(geo.size.width - knob, 1)
                let f = min(max((drag.location.x - knob / 2) / track, 0), 1)
                value = range.lowerBound + Double(f) * (range.upperBound - range.lowerBound)
            })
        }
        .frame(height: 18)
        .opacity(isEnabled ? 1 : 0.6)
        .accessibilityElement()
        .accessibilityValue(Text(value, format: .number.precision(.fractionLength(0...2))))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let step = (range.upperBound - range.lowerBound) / 20
            switch direction {
            case .increment: value = min(value + step, range.upperBound)
            case .decrement: value = max(value - step, range.lowerBound)
            @unknown default: break
            }
        }
    }

    /// Where `value` sits in `range`, 0...1. An empty range reads as the start.
    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }
}

/// The look of a macOS pop-up button, with the value and the up-down chevrons.
/// Use it as the label of a `Menu`, or on its own where the AppKit control can't draw.
public struct PopUpField: View {
    let value: String
    var symbol: String?
    @Environment(\.colorScheme) private var scheme

    public init(_ value: String, symbol: String? = nil) {
        self.value = value
        self.symbol = symbol
    }

    public var body: some View {
        let ink = Ink(scheme)
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        HStack(spacing: PUI.Space.s) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 11, weight: .medium)).foregroundStyle(ink.secondary)
            }
            Text(value).font(PUI.Font.callout).foregroundStyle(ink.primary).lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(ink.secondary)
        }
        .padding(.leading, PUI.Space.m)
        .padding(.trailing, PUI.Space.s)
        .frame(height: PUI.Control.small)
        .background {
            ZStack {
                shape.fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.9))
                shape.strokeBorder(Color.black.opacity(scheme == .dark ? 0.3 : 0.12), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.06), radius: 0.8, y: 0.5)
        }
    }
}

/// A round checkbox or radio mark in the accent.
public struct CheckMark: View {
    var on: Bool
    var color: Color?
    var size: CGFloat
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ on: Bool, color: Color? = nil, size: CGFloat = 16) {
        self.on = on
        self.color = color
        self.size = size
    }

    public var body: some View {
        let c = color ?? accent.color
        ZStack {
            if on {
                Circle().fill(c)
                Image(systemName: "checkmark").font(.system(size: size * 0.5, weight: .bold)).foregroundStyle(.white)
            } else {
                Circle().strokeBorder(Ink(scheme).tertiary, lineWidth: 1.2)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chip

/// A selectable chip on a card, like Tuuli's fan modes. Active: accent wash and legible text.
public struct Chip: View {
    let title: String
    var symbol: String?
    var active: Bool
    var action: () -> Void
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ title: String, symbol: String? = nil, active: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.active = active
        self.action = action
    }

    public var body: some View {
        let ink = Ink(scheme)
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.row, style: .continuous)
        Button(action: action) {
            HStack(spacing: PUI.Space.s) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 14)
                }
                Text(title).font(.system(size: 12, weight: active ? .semibold : .regular)).lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(active ? accent.legible(scheme) : ink.primary)
            .padding(.horizontal, PUI.Space.m + 2)
            .frame(height: PUI.Control.regular)
            .background {
                ZStack {
                    shape.fill(active ? accent.color.opacity(scheme == .dark ? 0.24 : 0.14) : ink.fill)
                    if active { shape.strokeBorder(accent.color.opacity(scheme == .dark ? 0.55 : 0.45), lineWidth: 1) }
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
