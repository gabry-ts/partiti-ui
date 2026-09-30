import SwiftUI
import PartitiUI

struct KiitoPopover: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        let accent = AppAccent.kiito
        PopoverScaffold {
            PopoverHeader(icon: Assets.icon(.kiito), name: "Kiito") {
                HeaderStatus("Right Button")
            }
        } content: {
            Card(tint: accent.color) {
                HStack(spacing: PUI.Space.l) {
                    ZStack {
                        Circle().fill(accent.color.opacity(scheme == .dark ? 0.25 : 0.18))
                        KiitoBall().foregroundStyle(accent.legible(scheme))
                    }
                    .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Enabled").font(PUI.Font.headline).foregroundStyle(ink.primary)
                        Text("Hold the right button and move to scroll").font(PUI.Font.caption).foregroundStyle(ink.secondary)
                    }
                    Spacer(minLength: 0)
                    Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle()).labelsHidden()
                }
            }
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.m) {
                    SectionHeader("Profile")
                    SegmentedPill([("Default", "Default"), ("Precise", "Precise"), ("Fast", "Fast"), ("Reading", "Reading")],
                                  selection: .constant("Default"), height: PUI.Control.regular - 2, stretch: true)
                }
            }
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.xs) {
                    SectionHeader("Scrolling")
                    row("Trigger", ink) { PopUpField("Right Button") }
                    Hairline()
                    VStack(spacing: PUI.Space.xs) {
                        HStack {
                            Text("Speed").font(PUI.Font.body).foregroundStyle(ink.primary)
                            Spacer()
                            Text("2.3").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                        }
                        PUISlider(value: .constant(2.3), in: 0.5...8)
                    }
                    .padding(.vertical, PUI.Space.xs)
                    Hairline()
                    row("Axis", ink) { PopUpField("Snap to Axis") }
                    Hairline()
                    row("Inertia", ink) {
                        Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle(mini: true)).labelsHidden()
                    }
                }
            }
            Card(padding: PUI.Space.m + 2) {
                HStack(spacing: PUI.Space.m) {
                    RowSymbol("xmark.app")
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Excluded Apps").font(PUI.Font.body).foregroundStyle(ink.primary)
                        Text("Blender, Figma, Parallels Desktop").font(PUI.Font.caption).foregroundStyle(ink.secondary)
                    }
                    Spacer()
                    Text("3").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(ink.tertiary)
                }
                .padding(.horizontal, PUI.Space.xxs)
            }
        } footer: {
            SampleFooter.make()
        }
    }

    private func row<C: View>(_ title: String, _ ink: Ink, @ViewBuilder _ control: () -> C) -> some View {
        HStack {
            Text(title).font(PUI.Font.body).foregroundStyle(ink.primary)
            Spacer()
            control()
        }
        .frame(height: PUI.Control.regular)
    }
}

// MARK: - Settings: Scrolling

/// A cursor style tile: preview glyph and name, selection in the accent.
struct CursorTile: View {
    let name: String
    let symbol: String
    var selected = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.puiAccent) private var accent

    var body: some View {
        let ink = Ink(scheme)
        let shape = RoundedRectangle(cornerRadius: PUI.Radius.row, style: .continuous)
        VStack(spacing: PUI.Space.xs) {
            ZStack {
                shape.fill(ink.fill)
                Image(systemName: symbol).font(.system(size: 15, weight: .medium)).foregroundStyle(ink.primary)
            }
            .frame(height: 38)
            .overlay(shape.strokeBorder(selected ? accent.color : .clear, lineWidth: 2))
            Text(name).font(PUI.Font.caption).foregroundStyle(selected ? accent.legible(scheme) : ink.secondary)
        }
    }
}

struct KiitoScrollingPane: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        SettingsPane {
            PaneHeader("Default", subtitle: "Active profile. Hold the trigger button and move the mouse to scroll.",
                       symbol: "computermouse.fill", color: AppAccent.kiito.color) {
                Button("Reset to Defaults") {}.buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
            }
        } content: {
            SettingsGroup("Activation") {
                SettingsRow("Trigger button") { PopUpField("Right Button") }
                SettingsRow("Stay on", subtitle: "Click once to start scrolling, click again to stop.") {
                    Toggle("", isOn: .constant(false)).toggleStyle(PUISwitchStyle()).labelsHidden()
                }
            }
            SettingsGroup("Scrolling") {
                SettingsRow("Speed") {
                    HStack(spacing: PUI.Space.m) {
                        PUISlider(value: .constant(2.3), in: 0.5...8).frame(width: 180)
                        ValueText("2.3")
                    }
                }
                SettingsRow("Axis", subtitle: "Scroll along one axis, switching when movement clearly turns to the other.") {
                    PopUpField("Snap to Axis")
                }
            }
            SettingsGroup("Cursor") {
                HStack(spacing: PUI.Space.m) {
                    CursorTile(name: "Circle", symbol: "circle.circle")
                    CursorTile(name: "Hand", symbol: "hand.raised.fill")
                    CursorTile(name: "Move", symbol: "arrow.up.and.down.and.arrow.left.and.right")
                    CursorTile(name: "Dot", symbol: "circle.fill", selected: true)
                    CursorTile(name: "Vertical", symbol: "arrow.up.and.down")
                    CursorTile(name: "Compass", symbol: "safari")
                    CursorTile(name: "Glass", symbol: "circle.dashed")
                    CursorTile(name: "None", symbol: "nosign")
                }
                .padding(PUI.Space.l)
            }
            .foregroundStyle(ink.primary)
        }
    }
}

enum KiitoSettings {
    static let sections: [SidebarSection] = [
        SidebarSection("Profiles", [
            SidebarItem("Default", symbol: "circle.circle", style: .plain, checked: true),
            SidebarItem("Precise", symbol: "circle.circle", style: .plain),
            SidebarItem("Fast", symbol: "circle.circle", style: .plain),
            SidebarItem("Reading", symbol: "circle.circle", style: .plain),
            SidebarItem("Add Profile", symbol: "plus", style: .plain)
        ]),
        SidebarSection(nil, [
            SidebarItem("Excluded Apps", symbol: "xmark.app.fill", style: .tile(.red)),
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]
}
