import SwiftUI
import PartitiUI

// MARK: - Components sheet

struct ComponentsSheet: View {
    let dark: Bool
    static let size = CGSize(width: 1280, height: 690)

    var body: some View {
        let s = Self.size
        ZStack(alignment: .topLeading) {
            Wallpaper(dark: dark)
                .blur(radius: 50, opaque: true)
                .frame(width: s.width, height: s.height, alignment: .topLeading)
                .clipped()
            Rectangle().fill(dark ? Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.80) : Color(red: 0.975, green: 0.975, blue: 0.985).opacity(0.78))
            SheetContent()
                .padding(40)
        }
        .frame(width: s.width, height: s.height)
        .clipped()
        .environment(\.colorScheme, dark ? .dark : .light)
        .puiGlassRendering(.painted)
        .puiAccent(.kello)
    }
}

private struct SheetContent: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Partiti UI").font(.system(size: 28, weight: .bold)).foregroundStyle(ink.primary)
                Text("Tokens and components").font(.system(size: 15)).foregroundStyle(ink.secondary)
                Spacer()
                Text("v0.1").font(PUI.Font.label).monospacedDigit().foregroundStyle(ink.tertiary)
            }
            HStack(alignment: .top, spacing: 28) {
                colorColumn(ink).frame(width: 236)
                geometryColumn(ink).frame(width: 272)
                typeColumn(ink).frame(width: 300)
                controlsColumn(ink)
            }
            HStack(alignment: .top, spacing: 20) {
                statCard(ink).frame(width: 236)
                listCard(ink).frame(width: 300)
                EmptyState(symbol: "tray", title: "No usage yet", message: "Numbers show up here as soon as there is something to count.")
                    .frame(width: 240)
                settingsSample(ink)
            }
        }
    }

    private func title(_ t: String, _ ink: Ink) -> some View {
        Text(t.uppercased()).font(PUI.Font.badge).tracking(PUI.Font.badgeTracking).foregroundStyle(ink.tertiary)
    }

    // Colors
    private func colorColumn(_ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Accents", ink)
            ForEach(AppAccent.allCases, id: \.self) { a in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous).fill(a.color)
                        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                        .frame(width: 28, height: 28)
                    Assets.icon(a).resizable().frame(width: 22, height: 22)
                    Text(a.name).font(PUI.Font.headline).foregroundStyle(ink.primary)
                    Spacer()
                    Text(a.hex).font(PUI.Font.callout).monospacedDigit().foregroundStyle(ink.secondary)
                }
            }
            title("Neutrals", ink).padding(.top, 6)
            HStack(spacing: 8) {
                swatch(ink.primary, "primary", ink)
                swatch(ink.secondary, "secondary", ink)
                swatch(ink.tertiary, "tertiary", ink)
                swatch(ink.hairline, "hairline", ink)
            }
            HStack(spacing: 8) {
                swatch(ink.green, "ok", ink)
                swatch(ink.orange, "warning", ink)
                swatch(ink.red, "error", ink)
                swatch(PUI.coffee, "coffee", ink)
            }
        }
    }

    private func swatch(_ c: Color, _ name: String, _ ink: Ink) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(c)
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(ink.hairline, lineWidth: 0.5))
                .frame(height: 22)
            Text(name).font(PUI.Font.caption).foregroundStyle(ink.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // Spacing, radii, controls
    private func geometryColumn(_ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Spacing", ink)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(PUI.Space.scale, id: \.name) { step in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2).fill(AppAccent.kello.color.opacity(0.85))
                            .frame(width: step.value, height: step.value)
                        Text("\(Int(step.value))").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                    }
                }
            }
            .frame(height: 42, alignment: .bottom)
            title("Radii", ink).padding(.top, 6)
            HStack(spacing: 12) {
                radius(PUI.Radius.card, "card", ink)
                radius(PUI.Radius.group, "group", ink)
                radius(PUI.Radius.row, "row", ink)
                VStack(spacing: 5) {
                    IconTile("app.fill", color: .gray, size: 40)
                    Text("tile 27%").font(PUI.Font.caption).foregroundStyle(ink.secondary)
                }
            }
            title("Controls", ink).padding(.top, 6)
            HStack(alignment: .bottom, spacing: 12) {
                control(PUI.Control.small, ink)
                control(PUI.Control.regular, ink)
                control(PUI.Control.large, ink)
            }
            title("Popover", ink).padding(.top, 6)
            HStack(spacing: 18) {
                spec("320", "regular", ink)
                spec("260", "compact", ink)
                spec("12", "margin", ink)
                spec("8", "gap", ink)
            }
        }
    }

    private func radius(_ r: CGFloat, _ name: String, _ ink: Ink) -> some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color.white.opacity(scheme == .dark ? 0.07 : 0.8))
                .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(ink.quaternary, lineWidth: 1))
                .frame(width: 48, height: 40)
            Text("\(name) \(Int(r))").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
        }
    }

    private func control(_ h: CGFloat, _ ink: Ink) -> some View {
        VStack(spacing: 5) {
            Capsule().fill(Color.clear).frame(width: 76, height: h).puiGlass(Capsule())
                .overlay(Text("\(Int(h))").font(PUI.Font.label).monospacedDigit().foregroundStyle(ink.secondary))
            Text(h == PUI.Control.small ? "small" : (h == PUI.Control.regular ? "regular" : "large"))
                .font(PUI.Font.caption).foregroundStyle(ink.secondary)
        }
    }

    private func spec(_ v: String, _ name: String, _ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(v).font(PUI.Font.stat).foregroundStyle(ink.primary)
            Text(name).font(PUI.Font.caption).foregroundStyle(ink.secondary)
        }
    }

    // Type
    private func typeColumn(_ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            title("Type scale", ink)
            ForEach(PUI.Font.scale, id: \.name) { t in
                HStack(alignment: .firstTextBaseline) {
                    Text(sample(t.name))
                        .font(t.font)
                        .tracking(t.name == "badge" ? PUI.Font.badgeTracking : 0)
                        .foregroundStyle(["label", "caption"].contains(t.name) ? ink.secondary : ink.primary)
                    Spacer()
                    Text("\(t.name) · \(t.spec)").font(PUI.Font.caption).foregroundStyle(ink.tertiary)
                }
            }
        }
    }

    private func sample(_ name: String) -> String {
        switch name {
        case "display": "64°"
        case "title": "Statistics"
        case "stat": "33.1M"
        case "paneTitle": "Calendars"
        case "headline": "Design review"
        case "body": "Left fan"
        case "callout": "Settings…"
        case "label": "5-hour window"
        case "caption": "resets 13:00"
        default: "NEXT UP"
        }
    }

    // Controls
    private func controlsColumn(_ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Controls", ink)
            HStack(spacing: 8) {
                GlassCircleButton("magnifyingglass") {}
                GlassCircleButton("pin.fill", active: true) {}
                GlassCapsule {
                    IconButton("chevron.left") {}
                    IconButton("plus") {}
                    IconButton("ellipsis") {}
                }
            }
            SegmentedPill([(0, "Agenda"), (1, "Reminders")], selection: .constant(0))
            HStack(spacing: 8) {
                Button {} label: { Label("Stop Recording", systemImage: "stop.fill").labelStyle(TightLabelStyle(spacing: 6)) }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                Button("Pause") {}.buttonStyle(SecondaryButtonStyle())
            }
            HStack(spacing: 10) {
                CoffeeButton {}
                JoinButton {}
            }
            HStack(spacing: 12) {
                Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle()).labelsHidden().fixedSize()
                Toggle("", isOn: .constant(false)).toggleStyle(PUISwitchStyle()).labelsHidden().fixedSize()
                PUISlider(value: .constant(0.6)).frame(width: 120)
            }
            PopUpField("Right Button")
            HStack(spacing: 6) {
                Badge("Next up")
                Badge("est.", style: .neutral)
                Badge("3", color: ink.red, style: .solid)
                Badge("Active", color: AppAccent.tuuli.color)
            }
            HStack(spacing: 6) {
                Chip("Curve", symbol: "point.topleft.down.to.point.bottomright.curvepath", active: true) {}.frame(width: 128)
                Chip("Manual", symbol: "slider.horizontal.3") {}.frame(width: 128)
            }
        }
    }

    // Cards
    private func statCard(_ ink: Ink) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    GaugeRing(0.62, color: AppAccent.mittari.color, lineWidth: 6, size: 56) {
                        Text("62%").font(PUI.Font.label).monospacedDigit().foregroundStyle(ink.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time to reset").font(PUI.Font.label).foregroundStyle(ink.secondary)
                        BigNumber("2h 18m")
                    }
                }
                Meter(0.34, color: AppAccent.mittari.color)
                HStack(alignment: .top) {
                    StatTile("Today", value: "33.1M", detail: "$72.40")
                    StatTile("Month", value: "642M", detail: "$1,380")
                }
            }
        }
    }

    private func listCard(_ ink: Ink) -> some View {
        VStack(spacing: 8) {
            PopoverHeader(icon: Assets.icon(.tuuli), name: "Tuuli") { HeaderStatus("Power Adapter", symbol: "bolt.fill") }
            Card {
                VStack(alignment: .leading, spacing: 4) {
                    SectionHeader("Temperatures") { Text("4 sensors") }
                    Row("CPU Hottest", leading: { RowSymbol("cpu") }, trailing: { Text("64°").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary) })
                    Hairline(leading: 24)
                    Row("Weekly sync", subtitle: "Today, 9:30 · 28 min", leading: { RowSymbol("text.bubble") }, trailing: { Image(systemName: "doc.on.doc").font(.system(size: 11)).foregroundStyle(ink.tertiary) })
                }
            }
            SampleFooter.make()
        }
    }

    private func settingsSample(_ ink: Ink) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            PaneHeader("General", subtitle: "Startup and menu bar icon.", symbol: "gearshape.fill", color: .gray)
            SettingsGroup("Startup") {
                SettingsRow("Launch at login") { Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle()).labelsHidden() }
                SettingsRow("Show icon in menu bar") { Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle()).labelsHidden() }
            }
        }
    }
}

// MARK: - Menu bar strip

struct MenuBarStrip: View {
    let dark: Bool
    let geometry: MenuBarGeometry
    static let width: CGFloat = 720

    var body: some View {
        let W = Self.width
        ZStack(alignment: .topLeading) {
            Wallpaper(dark: dark)
                .frame(width: W, height: 96, alignment: .topLeading)
                .clipped()
            FakeMenuBar(width: W, highlight: nil)
            ForEach(StatusItems.order, id: \.self) { a in
                let x = geometry.center(of: a, width: W)
                VStack(spacing: 4) {
                    Rectangle().fill(Color.white.opacity(0.55)).frame(width: 1, height: 14)
                    Assets.icon(a).resizable().frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    Text(a.name).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 0.5)
                }
                .frame(width: 70)
                .position(x: x, y: 28 + 32)
            }
        }
        .frame(width: W, height: 96, alignment: .topLeading)
        .clipped()
        .environment(\.colorScheme, dark ? .dark : .light)
        .puiGlassRendering(.painted)
    }
}
