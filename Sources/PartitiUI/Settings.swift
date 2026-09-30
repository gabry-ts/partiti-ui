import SwiftUI

// MARK: - Icon tile

/// A System Settings style tile: white symbol on a vertical gradient of a system color,
/// rounded at 27% of the side. 22 pt in the sidebar, 40 pt in pane headers.
public struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat

    public init(_ symbol: String, color: Color, size: CGFloat = PUI.Window.sidebarTile) {
        self.symbol = symbol
        self.color = color
        self.size = size
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.tile(size), style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [PUI.mix(color, with: .white, by: 0.18), PUI.mix(color, with: .black, by: 0.10)],
                                      startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
            Image(systemName: symbol)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: 0.8, y: 0.5)
    }
}

// MARK: - Pane header

/// Opens every settings pane: tile 40, title in paneTitle, one-line subtitle in 12 secondary.
public struct PaneHeader<Trailing: View>: View {
    let symbol: String
    let color: Color
    let title: Text
    let subtitle: Text
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme

    public init(_ title: Text, subtitle: Text, symbol: String, color: Color, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.color = color
        self.trailing = trailing()
    }

    /// `title` and `subtitle` are looked up in the app's string catalog.
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey, symbol: String, color: Color,
                @ViewBuilder trailing: () -> Trailing) {
        self.init(Text(title), subtitle: Text(subtitle), symbol: symbol, color: color, trailing: trailing)
    }

    /// `title` and `subtitle` are shown as given.
    @_disfavoredOverload
    public init(_ title: String, subtitle: String, symbol: String, color: Color, @ViewBuilder trailing: () -> Trailing) {
        self.init(Text(verbatim: title), subtitle: Text(verbatim: subtitle), symbol: symbol, color: color, trailing: trailing)
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.l) {
            IconTile(symbol, color: color, size: PUI.Window.paneTile)
            VStack(alignment: .leading, spacing: PUI.Space.xxs) {
                title.font(PUI.Font.paneTitle).foregroundStyle(ink.primary)
                subtitle.font(PUI.Font.callout).foregroundStyle(ink.secondary).lineLimit(2)
            }
            Spacer(minLength: PUI.Space.l)
            trailing
        }
    }
}

public extension PaneHeader where Trailing == EmptyView {
    init(_ title: Text, subtitle: Text, symbol: String, color: Color) {
        self.init(title, subtitle: subtitle, symbol: symbol, color: color) { EmptyView() }
    }

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey, symbol: String, color: Color) {
        self.init(title, subtitle: subtitle, symbol: symbol, color: color) { EmptyView() }
    }

    @_disfavoredOverload
    init(_ title: String, subtitle: String, symbol: String, color: Color) {
        self.init(title, subtitle: subtitle, symbol: symbol, color: color) { EmptyView() }
    }
}

// MARK: - Grouped form

/// A grouped settings section: header label, rows separated by hairlines, footer note.
/// Each direct child of `content` is a row. Hairlines between rows need macOS 15;
/// on macOS 14 the rows sit in the same group without them.
public struct SettingsGroup<Content: View>: View {
    var header: Text?
    var footer: Text?
    let content: Content
    @Environment(\.colorScheme) private var scheme

    public init(_ header: Text, footer: Text? = nil, @ViewBuilder _ content: () -> Content) {
        self.init(header: header, footer: footer, content)
    }

    /// `header` and `footer` are looked up in the app's string catalog.
    public init(_ header: LocalizedStringKey? = nil, footer: LocalizedStringKey? = nil, @ViewBuilder _ content: () -> Content) {
        self.init(header: header.map { Text($0) }, footer: footer.map { Text($0) }, content)
    }

    /// `header` and `footer` are shown as given.
    @_disfavoredOverload
    public init(_ header: String? = nil, footer: String? = nil, @ViewBuilder _ content: () -> Content) {
        self.init(header: header.map { Text(verbatim: $0) }, footer: footer.map { Text(verbatim: $0) }, content)
    }

    init(header: Text?, footer: Text?, _ content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        let ink = Ink(scheme)
        let dark = scheme == .dark
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.group, style: .continuous)
        VStack(alignment: .leading, spacing: PUI.Space.s) {
            if let header {
                header.font(.system(size: 11, weight: .semibold)).foregroundStyle(ink.secondary)
                    .padding(.leading, PUI.Space.xs)
            }
            VStack(spacing: 0) {
                if #available(macOS 15, *) {
                    Group(subviews: content) { rows in
                        ForEach(rows.indices, id: \.self) { i in
                            rows[i]
                            if i < rows.count - 1 { Hairline().padding(.horizontal, PUI.Space.l) }
                        }
                    }
                } else {
                    content
                }
            }
            .background {
                ZStack {
                    shape.fill(dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                    shape.strokeBorder(dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07), lineWidth: 0.5)
                }
            }
            if let footer {
                footer
                    .font(PUI.Font.caption.leading(.standard))
                    .foregroundStyle(ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, PUI.Space.xs)
            }
        }
    }
}

/// A settings row: title, optional subtitle, control on the right.
public struct SettingsRow<Control: View>: View {
    let title: Text
    var subtitle: Text?
    let control: Control
    @Environment(\.colorScheme) private var scheme

    public init(_ title: Text, subtitle: Text? = nil, @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    /// `title` and `subtitle` are looked up in the app's string catalog.
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, @ViewBuilder control: () -> Control) {
        self.init(Text(title), subtitle: subtitle.map { Text($0) }, control: control)
    }

    /// `title` and `subtitle` are shown as given.
    @_disfavoredOverload
    public init(_ title: String, subtitle: String? = nil, @ViewBuilder control: () -> Control) {
        self.init(Text(verbatim: title), subtitle: subtitle.map { Text(verbatim: $0) }, control: control)
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.l) {
            VStack(alignment: .leading, spacing: 1) {
                title.font(PUI.Font.body).foregroundStyle(ink.primary)
                if let subtitle {
                    subtitle.font(PUI.Font.caption).foregroundStyle(ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: PUI.Space.l)
            control
        }
        .padding(.horizontal, PUI.Space.l)
        .padding(.vertical, PUI.Space.m)
        .frame(minHeight: 38)
    }
}

// MARK: - Sidebar

/// One sidebar entry. Fixed panes use a colored tile; user-made items use a plain symbol.
/// The title doubles as the id, so titles must be unique within a sidebar.
public struct SidebarItem: Identifiable, Sendable {
    /// How the entry's symbol is drawn.
    public enum Style: Sendable {
        /// A white symbol on an `IconTile` of this color, for the app's fixed panes.
        case tile(Color)
        /// A bare symbol, for items the user made, such as modes or profiles.
        case plain
    }
    public let id: String
    /// The title as given, or the id for a localized title.
    public let title: String
    /// What the sidebar shows.
    public let label: Text
    public let symbol: String
    public let style: Style
    /// Marks the active user item (current mode or profile).
    public let checked: Bool

    /// `title` is shown as given and doubles as the id.
    public init(_ title: String, symbol: String, style: Style, checked: Bool = false) {
        self.init(id: title, label: Text(verbatim: title), symbol: symbol, style: style, checked: checked)
    }

    /// `title` is looked up in the app's string catalog. `id` is the stable value
    /// the selection holds, the same in every language.
    public init(_ title: LocalizedStringKey, id: String, symbol: String, style: Style, checked: Bool = false) {
        self.init(id: id, label: Text(title), symbol: symbol, style: style, checked: checked)
    }

    /// `id` is the stable value the selection holds, the same in every language.
    public init(_ title: Text, id: String, symbol: String, style: Style, checked: Bool = false) {
        self.init(id: id, label: title, symbol: symbol, style: style, checked: checked)
    }

    private init(id: String, label: Text, symbol: String, style: Style, checked: Bool) {
        self.id = id
        self.title = id
        self.label = label
        self.symbol = symbol
        self.style = style
        self.checked = checked
    }
}

/// A group of sidebar entries, with an optional title.
public struct SidebarSection: Identifiable, Sendable {
    public let id: String
    /// The title as given, or nil for a localized or untitled section.
    public let title: String?
    /// What the sidebar shows above the items.
    public let label: Text?
    public let items: [SidebarItem]

    /// The id is derived from the title, or from the items for an untitled section,
    /// so it stays stable across updates. `title` is shown as given.
    @_disfavoredOverload
    public init(_ title: String?, _ items: [SidebarItem]) {
        self.id = title ?? Self.itemsID(items)
        self.title = title
        self.label = title.map { Text(verbatim: $0) }
        self.items = items
    }

    /// `title` is looked up in the app's string catalog; the id is derived from the items.
    public init(_ title: LocalizedStringKey, _ items: [SidebarItem]) {
        self.init(Text(title), items)
    }

    /// The id is derived from the items.
    public init(_ title: Text, _ items: [SidebarItem]) {
        self.id = Self.itemsID(items)
        self.title = nil
        self.label = title
        self.items = items
    }

    private static func itemsID(_ items: [SidebarItem]) -> String {
        items.map(\.id).joined(separator: "|")
    }
}

/// The settings sidebar: sections of entries, selection as an accent wash.
/// `selection` holds the id of the selected `SidebarItem`.
public struct SettingsSidebar: View {
    let sections: [SidebarSection]
    @Binding var selection: String
    var topInset: CGFloat
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    /// `topInset` leaves room for the traffic lights in a window with a full-size content view.
    public init(_ sections: [SidebarSection], selection: Binding<String>, topInset: CGFloat = 44) {
        self.sections = sections
        self._selection = selection
        self.topInset = topInset
    }

    public var body: some View {
        let ink = Ink(scheme)
        VStack(alignment: .leading, spacing: PUI.Space.l) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 1) {
                    if let label = section.label {
                        label.font(.system(size: 11, weight: .semibold)).foregroundStyle(ink.tertiary)
                            .padding(.leading, PUI.Space.m + 2).padding(.bottom, PUI.Space.xs)
                    }
                    ForEach(section.items) { item in
                        row(item, ink)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, topInset)
        .padding(.horizontal, PUI.Space.m + 2)
        .padding(.bottom, PUI.Space.l)
    }

    private func row(_ item: SidebarItem, _ ink: Ink) -> some View {
        let on = item.id == selection
        return Button { selection = item.id } label: { rowLabel(item, on: on, ink) }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func rowLabel(_ item: SidebarItem, on: Bool, _ ink: Ink) -> some View {
        HStack(spacing: PUI.Space.m) {
            switch item.style {
            case .tile(let color):
                IconTile(item.symbol, color: color)
            case .plain:
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(on ? accent.legible(scheme) : ink.secondary)
                    .frame(width: PUI.Window.sidebarTile, height: PUI.Window.sidebarTile)
            }
            item.label.font(PUI.Font.body).foregroundStyle(ink.primary).lineLimit(1)
            Spacer(minLength: 0)
            if item.checked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(accent.legible(scheme))
            }
        }
        .padding(.horizontal, PUI.Space.s)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: PUI.Radius.row, style: .continuous)
                .fill(on ? accent.color.opacity(scheme == .dark ? 0.28 : 0.16) : .clear))
        .contentShape(RoundedRectangle(cornerRadius: PUI.Radius.row, style: .continuous))
    }
}

/// The settings window layout: a floating glass sidebar on the left, the selected pane on the right.
/// Give the window a full-size content view with a transparent title bar: the layout extends
/// under the title bar by itself, so the sidebar runs under the traffic lights; the sidebar
/// radius is concentric with the window corner.
public struct SettingsWindow<Pane: View>: View {
    let sections: [SidebarSection]
    @Binding var selection: String
    let pane: Pane
    @Environment(\.colorScheme) private var scheme

    /// `pane` is built for the current `selection`, typically with a `switch` on it.
    public init(sections: [SidebarSection], selection: Binding<String>, @ViewBuilder pane: () -> Pane) {
        self.sections = sections
        self._selection = selection
        self.pane = pane()
    }

    public var body: some View {
        let dark = scheme == .dark
        let sidebarShape = RoundedRectangle(cornerRadius: PUI.Radius.concentric(PUI.Radius.window, inset: PUI.Space.m),
                                            style: .continuous)
        HStack(spacing: 0) {
            SettingsSidebar(sections, selection: $selection)
                .frame(width: PUI.Window.sidebar)
                .frame(maxHeight: .infinity, alignment: .top)
                .puiGlass(sidebarShape)
                .padding(PUI.Space.m)
            pane
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(dark ? Color(white: 0.135) : Color(white: 0.955))
        .ignoresSafeArea(.container, edges: .top)
    }
}

/// A settings pane: header, then groups, with the form width capped in wide windows.
public struct SettingsPane<Header: View, Content: View>: View {
    let header: Header
    let content: Content

    public init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PUI.Space.xl + 2) {
            header
            content
        }
        .frame(maxWidth: PUI.Window.formMaxWidth)
        .padding(.horizontal, PUI.Space.xxl)
        .padding(.top, PUI.Space.xxl + PUI.Space.xs)
        .padding(.bottom, PUI.Space.xxl)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - About

/// The About pane, identical in every app: icon 96, name in title, tagline, version,
/// the Updates group, then the Coffee line and capsule.
public struct AboutPane: View {
    let brand: PartitiBrand
    let version: String
    @Binding var checksAutomatically: Bool
    let onCheckForUpdates: () -> Void
    let canCheckForUpdates: Bool
    let onBuyMeACoffee: () -> Void
    @Environment(\.colorScheme) private var scheme

    /// `version` is shown as given, for example "Version 1.2 (34)".
    /// `checksAutomatically` is the updater's automatic-check setting.
    /// `canCheckForUpdates` false dims the Check for Updates… button, for example while a check runs.
    public init(brand: PartitiBrand,
                version: String,
                checksAutomatically: Binding<Bool>,
                onCheckForUpdates: @escaping () -> Void,
                canCheckForUpdates: Bool = true,
                onBuyMeACoffee: @escaping () -> Void) {
        self.brand = brand
        self.version = version
        self._checksAutomatically = checksAutomatically
        self.onCheckForUpdates = onCheckForUpdates
        self.canCheckForUpdates = canCheckForUpdates
        self.onBuyMeACoffee = onBuyMeACoffee
    }

    public var body: some View {
        let ink = Ink(scheme)
        VStack(spacing: 0) {
            brand.icon
                .resizable()
                .interpolation(.high)
                .frame(width: 112, height: 112)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .accessibilityHidden(true)
            Text(verbatim: brand.name).font(PUI.Font.title).foregroundStyle(ink.primary)
                .padding(.top, PUI.Space.l)
            Text(verbatim: brand.tagline).font(PUI.Font.body).foregroundStyle(ink.secondary)
                .padding(.top, PUI.Space.xxs)
            Text(verbatim: version).font(.system(size: 11)).monospacedDigit().foregroundStyle(ink.tertiary)
                .padding(.top, PUI.Space.s)
                .textSelection(.enabled)

            SettingsGroup(Text(pui: "Updates"),
                          footer: Text(pui: "\(brand.name) asks once, the first time it can check, whether to check automatically from then on.")) {
                SettingsRow(Text(pui: "Automatically check for updates")) {
                    Toggle(isOn: $checksAutomatically) { Text(pui: "Automatically check for updates") }
                        .toggleStyle(PUISwitchStyle(showsLabel: false))
                }
                SettingsRow(Text(pui: "Check for updates now")) {
                    Button(action: onCheckForUpdates) { Text(pui: "Check for Updates…") }
                        .buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
                        .disabled(!canCheckForUpdates)
                }
            }
            .frame(maxWidth: 420)
            .padding(.top, PUI.Space.xxl)

            Text(verbatim: brand.coffeeLine)
                .font(PUI.Font.callout)
                .foregroundStyle(ink.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PUI.Space.xxl)
            CoffeeButton(action: onBuyMeACoffee)
                .padding(.top, PUI.Space.l)
        }
        .frame(maxWidth: .infinity)
    }
}
