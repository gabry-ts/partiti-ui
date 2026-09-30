import AppKit
import SwiftUI

// MARK: - Scaffold

/// The standard popover: header, content, optional toolbar, footer, in that order,
/// with the popover margin and the card gap from the tokens.
public struct PopoverScaffold<Header: View, Content: View, Footer: View>: View {
    var width: CGFloat
    let header: Header
    let content: Content
    let footer: Footer

    public init(width: CGFloat = PUI.Popover.regular,
                @ViewBuilder header: () -> Header,
                @ViewBuilder content: () -> Content,
                @ViewBuilder footer: () -> Footer) {
        self.width = width
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: PUI.Popover.cardGap) {
            header
            content
            footer
        }
        .padding(PUI.Popover.margin)
        .frame(width: width)
    }
}

// MARK: - Header

/// The popover header, 22 pt: app icon at 16 pt, the app name in headline,
/// a status or round button on the right.
public struct PopoverHeader<Trailing: View>: View {
    let icon: Image
    let name: String
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme

    public init(icon: Image, name: String, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.name = name
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: PUI.Space.s) {
            icon
                .resizable()
                .interpolation(.high)
                .frame(width: PUI.Popover.headerIcon + 4, height: PUI.Popover.headerIcon + 4)
                .padding(-2)
                .frame(width: PUI.Popover.headerIcon, height: PUI.Popover.headerIcon)
            Text(name).font(PUI.Font.headline).foregroundStyle(Ink(scheme).primary)
            Spacer(minLength: PUI.Space.m)
            trailing
        }
        .frame(height: PUI.Popover.headerHeight)
        .padding(.horizontal, PUI.Space.xs)
    }
}

public extension PopoverHeader where Trailing == EmptyView {
    init(icon: Image, name: String) {
        self.init(icon: icon, name: name) { EmptyView() }
    }
}

/// A status line for the header's trailing side: optional symbol, caption text.
public struct HeaderStatus: View {
    let text: String
    var symbol: String?
    var color: Color?
    @Environment(\.colorScheme) private var scheme

    public init(_ text: String, symbol: String? = nil, color: Color? = nil) {
        self.text = text
        self.symbol = symbol
        self.color = color
    }

    public var body: some View {
        HStack(spacing: PUI.Space.xs) {
            if let symbol { Image(systemName: symbol).font(.system(size: 10, weight: .medium)) }
            Text(text).font(PUI.Font.label)
        }
        .foregroundStyle(color ?? Ink(scheme).secondary)
    }
}

// MARK: - Toolbar

/// The optional toolbar: a selector on glass on the left, a glass capsule of icon buttons on the right.
public struct PopoverToolbar<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing

    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: PUI.Space.m) {
            leading
            Spacer(minLength: 0)
            trailing
        }
        .frame(height: PUI.Control.small + 2)
    }
}

// MARK: - Footer

/// One footer action: symbol and title in callout, borderless, hover highlight at radius 8.
public struct FooterButton: View {
    let title: String?
    let symbol: String
    var highlighted: Bool
    var action: () -> Void
    @State private var hovering = false

    /// `title` nil draws the symbol alone. `highlighted` keeps the hover look on,
    /// for example while a menu opened from the button is showing.
    public init(_ title: String?, symbol: String, highlighted: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.highlighted = highlighted
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            FooterLabel(title.map { Text($0) }, symbol: symbol, highlighted: highlighted || hovering)
        }
        .buttonStyle(.plain)
        .onHover { inside in withAnimation(PUI.Motion.hover) { hovering = inside } }
        .accessibilityLabel(title ?? symbol)
    }
}

/// The look shared by footer buttons and the footer menu, for building a footer item
/// that isn't a plain button, such as the label of a `Menu`. Dims when disabled.
public struct FooterLabel: View {
    let title: Text?
    let symbol: String
    let highlighted: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    /// `title` nil draws the symbol alone; `highlighted` draws the hover look.
    public init(_ title: Text? = nil, symbol: String, highlighted: Bool = false) {
        self.title = title
        self.symbol = symbol
        self.highlighted = highlighted
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.xs + 1) {
            Image(systemName: symbol).font(.system(size: 11, weight: .medium))
            if let title { title.font(PUI.Font.callout) }
        }
        .foregroundStyle(!isEnabled ? ink.quaternary : (highlighted ? ink.primary : ink.secondary))
        .padding(.horizontal, PUI.Space.s + 1)
        .frame(height: PUI.Control.small + 2)
        .puiHoverHighlight(highlighted && isEnabled)
        .contentShape(Rectangle())
    }
}

/// The standard footer, the same in every app: up to two app actions, Settings…,
/// the ⋯ menu with the app's own items, Check for Updates… and Buy Me a Coffee…, then Quit.
/// ⌘, and ⌘Q are bound here so every popover answers to them.
public struct PopoverFooter: View {
    /// An app-specific footer action, such as Recordings or Statistics….
    public struct Action: Identifiable {
        public let id: String
        public let title: String
        public let symbol: String
        public let perform: () -> Void

        public init(_ title: String, symbol: String, perform: @escaping () -> Void) {
            self.id = title
            self.title = title
            self.symbol = symbol
            self.perform = perform
        }
    }

    let actions: [Action]
    let onSettings: () -> Void
    let onCheckForUpdates: () -> Void
    let onBuyMeACoffee: () -> Void
    let onQuit: () -> Void
    let menuItems: AnyView?
    @Environment(\.puiGlassRendering) private var rendering

    /// Only the first two `actions` are shown, so the footer never wraps.
    /// `onQuit` defaults to terminating the app.
    public init(actions: [Action] = [],
                onSettings: @escaping () -> Void,
                onCheckForUpdates: @escaping () -> Void,
                onBuyMeACoffee: @escaping () -> Void,
                onQuit: @escaping () -> Void = { NSApplication.shared.terminate(nil) }) {
        self.actions = Array(actions.prefix(2))
        self.onSettings = onSettings
        self.onCheckForUpdates = onCheckForUpdates
        self.onBuyMeACoffee = onBuyMeACoffee
        self.onQuit = onQuit
        self.menuItems = nil
    }

    /// `menuItems` go at the top of the ⋯ menu, above a divider and the standard items:
    /// buttons, toggles, pickers or submenus, as in any `Menu`.
    public init<MenuItems: View>(actions: [Action] = [],
                                 onSettings: @escaping () -> Void,
                                 onCheckForUpdates: @escaping () -> Void,
                                 onBuyMeACoffee: @escaping () -> Void,
                                 onQuit: @escaping () -> Void = { NSApplication.shared.terminate(nil) },
                                 @ViewBuilder menuItems: () -> MenuItems) {
        self.actions = Array(actions.prefix(2))
        self.onSettings = onSettings
        self.onCheckForUpdates = onCheckForUpdates
        self.onBuyMeACoffee = onBuyMeACoffee
        self.onQuit = onQuit
        self.menuItems = AnyView(menuItems())
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { a in
                FooterButton(a.title, symbol: a.symbol, action: a.perform)
            }
            FooterButton("Settings…", symbol: "gearshape", action: onSettings)
                .keyboardShortcut(",", modifiers: .command)
            moreMenu
            Spacer(minLength: 0)
            FooterButton("Quit", symbol: "power", action: onQuit)
                .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, -PUI.Space.xxs)
    }

    /// A real menu when live; its label alone when painted, since menus don't render offscreen.
    @ViewBuilder private var moreMenu: some View {
        switch rendering {
        case .live:
            Menu {
                if let menuItems {
                    menuItems
                    Divider()
                }
                Button("Check for Updates…", action: onCheckForUpdates)
                Button("Buy Me a Coffee…", action: onBuyMeACoffee)
            } label: {
                FooterLabel(symbol: "ellipsis")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("More")
        case .painted:
            FooterLabel(symbol: "ellipsis")
        }
    }
}

// MARK: - Cards and rows

/// A content card: painted surface at radius 12 with 12 pt padding.
/// `tint` washes the card in a color, for the one card that is live (recording, next event).
public struct Card<Content: View>: View {
    var tint: Color?
    var padding: CGFloat
    let content: Content

    public init(tint: Color? = nil, padding: CGFloat = PUI.Popover.cardPadding, @ViewBuilder _ content: () -> Content) {
        self.tint = tint
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .puiSurface(tint: tint)
    }
}

/// The label at the top of a card, with an optional value or badge on the right.
public struct SectionHeader<Trailing: View>: View {
    let title: String
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme

    public init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(alignment: .firstTextBaseline, spacing: PUI.Space.s) {
            Text(title).font(PUI.Font.label).foregroundStyle(ink.secondary)
            Spacer(minLength: PUI.Space.m)
            trailing.font(PUI.Font.label).foregroundStyle(ink.secondary)
        }
    }
}

public extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) { self.init(title) { EmptyView() } }
}

/// A list row: optional leading view, title and subtitle, trailing view.
public struct Row<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String?
    let leading: Leading
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme

    public init(_ title: String, subtitle: String? = nil,
                @ViewBuilder leading: () -> Leading,
                @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(spacing: PUI.Space.m) {
            leading
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(PUI.Font.body).foregroundStyle(ink.primary).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(PUI.Font.caption).foregroundStyle(ink.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: PUI.Space.m)
            trailing
        }
        .frame(minHeight: subtitle == nil ? PUI.Control.small : PUI.Control.regular + 4)
    }
}

/// A row symbol in a fixed 16 pt column, so titles line up.
public struct RowSymbol: View {
    let name: String
    var color: Color?
    @Environment(\.colorScheme) private var scheme

    public init(_ name: String, color: Color? = nil) {
        self.name = name
        self.color = color
    }

    public var body: some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(color ?? Ink(scheme).secondary)
            .frame(width: 16)
    }
}

// MARK: - Empty state

/// The popover empty state: a card with a symbol, a headline and a caption.
public struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    @Environment(\.colorScheme) private var scheme

    public init(symbol: String, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }

    public var body: some View {
        let ink = Ink(scheme)
        VStack(spacing: PUI.Space.s) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(ink.tertiary)
                .frame(height: 28)
            Text(title).font(PUI.Font.headline).foregroundStyle(ink.primary)
            Text(message)
                .font(PUI.Font.caption)
                .foregroundStyle(ink.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, PUI.Space.xl)
        .padding(.horizontal, PUI.Space.l)
        .frame(maxWidth: .infinity)
        .puiSurface()
    }
}
