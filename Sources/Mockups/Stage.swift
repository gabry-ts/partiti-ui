import SwiftUI
import AppKit
import PartitiUI

// MARK: - Assets and brands

/// The app icons, bundled with the renderer.
enum Assets {
    static func icon(_ accent: AppAccent) -> Image {
        if let url = Bundle.module.url(forResource: "\(accent.rawValue)-icon", withExtension: "png", subdirectory: "Icons"),
           let img = NSImage(contentsOf: url) {
            return Image(nsImage: img)
        }
        return Image(systemName: "app.fill")
    }
}

/// The standard footer with no-op actions, for renders.
enum SampleFooter {
    @MainActor static func make(_ actions: [PopoverFooter.Action] = []) -> PopoverFooter {
        PopoverFooter(actions: actions, onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {}, onQuit: {})
    }
}

enum Brands {
    static func brand(_ a: AppAccent) -> PartitiBrand {
        switch a {
        case .tuuli: PartitiBrand(accent: a, tagline: "Temperatures and fans in your menu bar",
                                  coffeeLine: "Tuuli is free. If it keeps your Mac cool, you can buy me a coffee.", icon: Assets.icon(a))
        case .kaiku: PartitiBrand(accent: a, tagline: "Record and transcribe your calls",
                                  coffeeLine: "Kaiku is free. If it saves you some notes, you can buy me a coffee.", icon: Assets.icon(a))
        case .kiito: PartitiBrand(accent: a, tagline: "Trackball scrolling for any mouse",
                                  coffeeLine: "Kiito is free. If it makes scrolling a little nicer, you can buy me a coffee.", icon: Assets.icon(a))
        case .mittari: PartitiBrand(accent: a, tagline: "Claude Code usage in your menu bar",
                                    coffeeLine: "Mittari is free. If it helps you pace your work, you can buy me a coffee.", icon: Assets.icon(a))
        case .kello: PartitiBrand(accent: a, tagline: "A calendar for your menu bar",
                                  coffeeLine: "Kello is free. If it makes your days a little easier, you can buy me a coffee.", icon: Assets.icon(a))
        }
    }
}

// MARK: - Measuring

@MainActor
func measure<V: View>(_ view: V) -> CGSize {
    let host = NSHostingView(rootView: view.puiGlassRendering(.painted))
    return host.fittingSize
}

// MARK: - Wallpaper

/// A soft, Tahoe-like wallpaper, drawn at a fixed size so every crop and blur agrees.
struct Wallpaper: View {
    let dark: Bool
    static let size = CGSize(width: 1400, height: 1000)

    var body: some View {
        let w = Self.size.width, h = Self.size.height
        ZStack {
            LinearGradient(colors: dark
                           ? [Color(red: 0.04, green: 0.06, blue: 0.15), Color(red: 0.08, green: 0.12, blue: 0.30), Color(red: 0.16, green: 0.10, blue: 0.28)]
                           : [Color(red: 0.20, green: 0.40, blue: 0.78), Color(red: 0.42, green: 0.58, blue: 0.90), Color(red: 0.74, green: 0.62, blue: 0.86)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Ellipse().fill(Color(red: 0.25, green: 0.78, blue: 0.95).opacity(dark ? 0.32 : 0.55))
                .frame(width: 620, height: 380).position(x: w * 0.72, y: h * 0.10).blur(radius: 110)
            Ellipse().fill(Color(red: 1.0, green: 0.55, blue: 0.62).opacity(dark ? 0.26 : 0.50))
                .frame(width: 560, height: 420).position(x: w * 0.18, y: h * 0.82).blur(radius: 120)
            Ellipse().fill(Color(red: 0.48, green: 0.36, blue: 0.98).opacity(dark ? 0.40 : 0.40))
                .frame(width: 600, height: 520).position(x: w * 0.70, y: h * 0.70).blur(radius: 120)
            Ellipse().fill(Color(red: 1.0, green: 0.80, blue: 0.55).opacity(dark ? 0.10 : 0.30))
                .frame(width: 420, height: 300).position(x: w * 0.30, y: h * 0.30).blur(radius: 110)
        }
        .frame(width: w, height: h)
        .compositingGroup()
    }
}

// MARK: - Menu bar

/// The Kiito status glyph: a ball with a tapered trail, template-drawn.
struct KiitoBall: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width * 0.66, y: size.height * 0.34)
            let r = size.width * 0.27
            var trail = Path()
            trail.move(to: CGPoint(x: size.width * 0.02, y: size.height * 0.98))
            trail.addLine(to: CGPoint(x: c.x - r * 0.71, y: c.y - r * 0.71))
            trail.addLine(to: CGPoint(x: c.x + r * 0.71, y: c.y + r * 0.71))
            trail.closeSubpath()
            ctx.opacity = 0.5
            ctx.fill(trail, with: .foreground)
            ctx.opacity = 1
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .foreground)
        }
        .frame(width: 15, height: 15)
    }
}

/// The five Partiti status items, unified.
enum StatusItems {
    @MainActor @ViewBuilder
    static func item(_ a: AppAccent, highlighted: Bool) -> some View {
        switch a {
        case .tuuli:
            MenuBarItem(highlighted: highlighted) {
                MenuBarSymbol("fan.fill")
                Text("64°")
            }
        case .kaiku:
            MenuBarItem(highlighted: highlighted) {
                MenuBarPill("4:12").puiAccent(.kaiku)
            }
        case .kiito:
            MenuBarItem(highlighted: highlighted) {
                KiitoBall()
            }
        case .mittari:
            MenuBarItem(highlighted: highlighted) {
                MenuBarRing(0.62)
                Text("62%")
            }
        case .kello:
            MenuBarItem(highlighted: highlighted) {
                Text("Wed 30 Sep")
            }
        }
    }

    static let order: [AppAccent] = [.tuuli, .kaiku, .kiito, .mittari, .kello]
}

struct SystemItems: View {
    var body: some View {
        HStack(spacing: 0) {
            MenuBarItem { Image(systemName: "battery.75percent").font(.system(size: 15)) }
            MenuBarItem { Image(systemName: "wifi").font(.system(size: 13, weight: .medium)) }
            MenuBarItem { Image(systemName: "magnifyingglass").font(.system(size: 13, weight: .medium)) }
            MenuBarItem { Image(systemName: "switch.2").font(.system(size: 13, weight: .medium)) }
            MenuBarItem { Text("10:41") }
        }
    }
}

/// Measured geometry of the right side of the menu bar.
struct MenuBarGeometry {
    var itemWidths: [AppAccent: CGFloat] = [:]
    var systemWidth: CGFloat = 0
    static let spacing: CGFloat = 2
    static let trailing: CGFloat = 6

    @MainActor static func measure() -> MenuBarGeometry {
        var g = MenuBarGeometry()
        for a in StatusItems.order {
            g.itemWidths[a] = ceil(Mockups.measure(StatusItems.item(a, highlighted: false)).width)
        }
        g.systemWidth = ceil(Mockups.measure(SystemItems()).width)
        return g
    }

    /// Center x of an app item, measured from the left of a bar `width` wide.
    func center(of a: AppAccent, width: CGFloat) -> CGFloat {
        var x = width - Self.trailing - systemWidth - Self.spacing
        for item in StatusItems.order.reversed() {
            let w = itemWidths[item] ?? 0
            if item == a { return x - w / 2 }
            x -= w + Self.spacing
        }
        return 0
    }
}

struct FakeMenuBar: View {
    let width: CGFloat
    var highlight: AppAccent?
    var showsMenus = true

    var body: some View {
        HStack(spacing: 0) {
            if showsMenus {
                HStack(spacing: 18) {
                    Image(systemName: "apple.logo").font(.system(size: 14, weight: .medium))
                    Text("Finder").font(.system(size: 13, weight: .bold))
                    Text("File").font(.system(size: 13, weight: .medium))
                }
                .padding(.leading, 16)
            }
            Spacer(minLength: 0)
            HStack(spacing: MenuBarGeometry.spacing) {
                ForEach(StatusItems.order, id: \.self) { a in
                    StatusItems.item(a, highlighted: a == highlight)
                }
                SystemItems()
            }
            .padding(.trailing, MenuBarGeometry.trailing)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.22), radius: 1, y: 0.5)
        .frame(width: width, height: 28)
    }
}

// MARK: - Popover stage

/// A popover on the wallpaper, under its highlighted status item, with painted system glass.
struct PopoverStage<Content: View>: View {
    let dark: Bool
    let accent: AppAccent
    let size: CGSize
    let geometry: MenuBarGeometry
    let content: Content

    static var width: CGFloat { 720 }
    static var bottom: CGFloat { 40 }

    init(dark: Bool, accent: AppAccent, size: CGSize, geometry: MenuBarGeometry, @ViewBuilder content: () -> Content) {
        self.dark = dark
        self.accent = accent
        self.size = size
        self.geometry = geometry
        self.content = content()
    }

    var body: some View {
        let W = Self.width
        let top: CGFloat = 28 + 5
        let cx = geometry.center(of: accent, width: W)
        let x = min(max(cx - size.width / 2, 10), W - 10 - size.width)
        let H = top + size.height + Self.bottom
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.popover, style: .continuous)
        ZStack(alignment: .topLeading) {
            Wallpaper(dark: dark)
            FakeMenuBar(width: W, highlight: accent)

            ZStack(alignment: .topLeading) {
                Wallpaper(dark: dark)
                    .offset(x: -x, y: -top)
                    .blur(radius: 40, opaque: true)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .clipped()
                shape.fill(dark ? Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.70)
                                : Color(red: 0.975, green: 0.975, blue: 0.985).opacity(0.70))
                shape.fill(LinearGradient(colors: [Color.white.opacity(dark ? 0.05 : 0.30), .clear],
                                          startPoint: .top, endPoint: .center))
                content
                    .frame(width: size.width, height: size.height, alignment: .top)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .overlay(shape.inset(by: 0.5).strokeBorder(Color.white.opacity(dark ? 0.12 : 0.6), lineWidth: 0.5).padding(0.5))
            .overlay(shape.strokeBorder(Color.black.opacity(dark ? 0.6 : 0.14), lineWidth: 0.5))
            .background {
                shape.fill(Color.black)
                    .shadow(color: .black.opacity(dark ? 0.5 : 0.28), radius: 24, y: 12)
                    .shadow(color: .black.opacity(0.10), radius: 1.5, y: 0.5)
                    .mask {
                        Rectangle().padding(-120)
                            .overlay(shape.fill(Color.black).blendMode(.destinationOut))
                            .compositingGroup()
                    }
            }
            .offset(x: x, y: top)
        }
        .frame(width: W, height: H, alignment: .topLeading)
        .clipped()
        .environment(\.colorScheme, dark ? .dark : .light)
        .puiGlassRendering(.painted)
        .puiAccent(accent)
    }
}

// MARK: - Window stage

/// A settings window on a quiet desktop, with traffic lights and a window shadow.
struct WindowStage<Content: View>: View {
    let dark: Bool
    let accent: AppAccent
    let size: CGSize
    let content: Content
    static var margin: CGFloat { 44 }

    init(dark: Bool, accent: AppAccent, size: CGSize, @ViewBuilder content: () -> Content) {
        self.dark = dark
        self.accent = accent
        self.size = size
        self.content = content()
    }

    var body: some View {
        let m = Self.margin
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.window, style: .continuous)
        ZStack(alignment: .topLeading) {
            Wallpaper(dark: dark)
                .blur(radius: 60, opaque: true)
                .saturation(0.55)
                .overlay(dark ? Color.black.opacity(0.35) : Color.white.opacity(0.35))
                .frame(width: size.width + m * 2, height: size.height + m * 2, alignment: .topLeading)
                .clipped()
            ZStack(alignment: .topLeading) {
                content
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                TrafficLights().padding(.leading, 8 + 14).padding(.top, 8 + 14)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .overlay(shape.inset(by: 0.5).strokeBorder(Color.white.opacity(dark ? 0.10 : 0.7), lineWidth: 0.5).padding(0.5))
            .overlay(shape.strokeBorder(Color.black.opacity(dark ? 0.7 : 0.18), lineWidth: 0.5))
            .background {
                shape.fill(Color.black)
                    .shadow(color: .black.opacity(dark ? 0.55 : 0.22), radius: 28, y: 14)
                    .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
            }
            .offset(x: m, y: m)
        }
        .frame(width: size.width + m * 2, height: size.height + m * 2, alignment: .topLeading)
        .environment(\.colorScheme, dark ? .dark : .light)
        .puiGlassRendering(.painted)
        .puiAccent(accent)
    }
}

struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            light(Color(red: 1.0, green: 0.37, blue: 0.34))
            light(Color(red: 1.0, green: 0.74, blue: 0.18))
            light(Color(red: 0.16, green: 0.79, blue: 0.25))
        }
    }

    private func light(_ c: Color) -> some View {
        Circle().fill(c)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
            .frame(width: 12, height: 12)
    }
}

// MARK: - Small shared pieces

/// A stepper field: value text and the small up and down arrows of NSStepper.
struct StepperField: View {
    let value: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.s) {
            Text(value).font(PUI.Font.callout).monospacedDigit().foregroundStyle(ink.primary)
            VStack(spacing: 0) {
                Image(systemName: "chevron.up").font(.system(size: 7, weight: .bold))
                Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
            }
            .foregroundStyle(ink.secondary)
            .frame(width: 14, height: 20)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(ink.fill))
        }
    }
}

/// A value label for sliders in settings rows.
struct ValueText: View {
    let text: String
    @Environment(\.colorScheme) private var scheme
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(PUI.Font.callout).monospacedDigit().foregroundStyle(Ink(scheme).secondary)
            .frame(width: 44, alignment: .trailing)
    }
}

/// A scroll indicator, drawn at the right edge of scrolled panes.
struct ScrollIndicator: View {
    var offset: CGFloat = 0
    var length: CGFloat = 120
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Capsule().fill(Ink(scheme).tertiary)
            .frame(width: 5, height: length)
            .padding(.top, offset)
            .padding(.trailing, 4)
    }
}
