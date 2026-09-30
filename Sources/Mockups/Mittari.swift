import SwiftUI
import PartitiUI

/// Mittari's domain palette: levels and chart series.
enum Levels {
    static let normal = AppAccent.mittari.color
    static let warning = Color(red: 0.97, green: 0.47, blue: 0.18)
    static let critical = Color(red: 0.91, green: 0.27, blue: 0.30)
    static let series: [Color] = [AppAccent.mittari.color, Color(red: 0.36, green: 0.64, blue: 1.0),
                                  Color(red: 0.62, green: 0.52, blue: 0.95), Color(red: 0.30, green: 0.78, blue: 0.70)]
}

struct MittariPopover: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        PopoverScaffold {
            PopoverHeader(icon: Assets.icon(.mittari), name: "Mittari") {
                HeaderStatus("Auto limit", symbol: "info.circle")
            }
        } content: {
            // 5-hour window
            Card {
                HStack(spacing: PUI.Space.l) {
                    GaugeRing(0.62, lineWidth: 7, size: 76) {
                        VStack(spacing: 0) {
                            Text("62%").font(PUI.Font.stat).foregroundStyle(ink.primary)
                            Text("5h").font(PUI.Font.caption).foregroundStyle(ink.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: PUI.Space.xxs) {
                        HStack(spacing: PUI.Space.s) {
                            Text("5-hour window").font(PUI.Font.label).foregroundStyle(ink.secondary)
                            Badge("est.", style: .neutral)
                        }
                        Text("in 2h 18m").font(PUI.Font.headline).monospacedDigit().foregroundStyle(ink.primary)
                            .padding(.top, PUI.Space.xxs)
                        Text("resets 13:00").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                        Spacer(minLength: PUI.Space.s)
                        HStack {
                            Text("18.4M of ~29.7M tokens").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                            Spacer()
                            Text("$41.20").font(PUI.Font.caption.weight(.medium)).monospacedDigit().foregroundStyle(ink.primary)
                        }
                    }
                    .frame(height: 76)
                }
            }
            // Week
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.s) {
                    HStack(spacing: PUI.Space.s) {
                        Text("Last 7 days").font(PUI.Font.label).foregroundStyle(ink.secondary)
                        Badge("est.", style: .neutral)
                        Spacer()
                        Text("34%").font(PUI.Font.headline).monospacedDigit().foregroundStyle(ink.primary)
                    }
                    Meter(0.34)
                    HStack {
                        Text("212M tokens").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                        Spacer()
                        Text("$486.10").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                    }
                }
            }
            // Today and this month
            Card {
                HStack(alignment: .top, spacing: PUI.Space.l) {
                    StatTile("Today", value: "33.1M", detail: "$72.40 API equiv.")
                    Rectangle().fill(ink.hairline).frame(width: 0.5, height: 52)
                    StatTile("This month", value: "642M", detail: "$1,380 API equiv.")
                }
            }
            // Models
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.s) {
                    SectionHeader("Models, last 7 days")
                    slice("Opus 4.5", "118M", "$312.40", 0.56, Levels.series[0], ink)
                    slice("Sonnet 4.5", "81M", "$148.20", 0.38, Levels.series[1], ink)
                    slice("Haiku 4.5", "13M", "$9.10", 0.06, Levels.series[2], ink)
                }
            }
            // Projects
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.s) {
                    SectionHeader("Projects today")
                    slice("design-system", "14.2M", "$31.10", 0.43, Levels.series[0], ink)
                    slice("web-app", "9.8M", "$21.60", 0.30, Levels.series[0], ink)
                    slice("notes-api", "6.2M", "$13.50", 0.19, Levels.series[0], ink)
                    slice("Others (3)", "2.9M", "$6.20", 0.08, ink.tertiary, ink, secondary: true)
                }
            }
        } footer: {
            SampleFooter.make([.init("Statistics…", symbol: "chart.bar.xaxis") {}])
        }
    }

    private func slice(_ name: String, _ tokens: String, _ cost: String, _ share: Double, _ color: Color, _ ink: Ink, secondary: Bool = false) -> some View {
        VStack(spacing: PUI.Space.xs) {
            HStack(spacing: PUI.Space.s) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(name).font(PUI.Font.callout).foregroundStyle(secondary ? ink.secondary : ink.primary).lineLimit(1)
                Spacer()
                Text(tokens).font(PUI.Font.callout).monospacedDigit().foregroundStyle(ink.primary)
                Text(cost).font(PUI.Font.callout).monospacedDigit().foregroundStyle(ink.secondary)
                    .frame(width: 58, alignment: .trailing)
            }
            Meter(share, color: color, height: 4)
                .padding(.leading, 12)
        }
    }
}

// MARK: - Settings: Limits

struct MittariLimitsPane: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        SettingsPane {
            PaneHeader("Limits", subtitle: "What 100% means, and when the ring changes color.",
                       symbol: "gauge.with.dots.needle.67percent", color: .orange)
        } content: {
            SettingsGroup("100% is", footer: "Claude plan limits aren't written to the logs, so percentages are estimates against this reference. In Auto, the window or week in progress is left out of the reference, so a new record reads above 100%.") {
                radio("Auto", "Your busiest earlier 5-hour window in the last 30 days", true, ink)
                radio("Custom token budgets", "Set the 5-hour and weekly budgets yourself, in millions of tokens", false, ink)
                SettingsRow("Busiest earlier 5-hour window") {
                    Text("29.7M tokens").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                }
                SettingsRow("Busiest earlier 7 days") {
                    Text("624M tokens").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                }
            }
            SettingsGroup("Thresholds", footer: "The menu bar ring turns orange at the warning threshold and red at the critical one. You get at most one notification per level and window.") {
                HStack(spacing: PUI.Space.xxl) {
                    preview(0.62, "62%", "Normal", Levels.normal, ink)
                    preview(0.80, "80%", "Warning", Levels.warning, ink)
                    preview(0.94, "94%", "Critical", Levels.critical, ink)
                    Spacer()
                    VStack(alignment: .trailing, spacing: PUI.Space.xs) {
                        Meter(0.62, height: 6, marks: [0.75, 0.90]).frame(width: 220)
                        ZStack {
                            Text("0%").position(x: 8, y: 7)
                            Text("75%").position(x: 165, y: 7)
                            Text("90%").position(x: 198, y: 7)
                        }
                        .font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.tertiary)
                        .frame(width: 220, height: 14)
                    }
                }
                .padding(.horizontal, PUI.Space.l)
                .padding(.vertical, PUI.Space.l)
                SettingsRow("Warning at") { slider(0.75, "75%", Levels.warning) }
                SettingsRow("Critical at") { slider(0.90, "90%", Levels.critical) }
                SettingsRow("Notify when the 5-hour window crosses a threshold") {
                    Toggle("", isOn: .constant(true)).toggleStyle(PUISwitchStyle()).labelsHidden()
                }
            }
        }
    }

    private func radio(_ title: String, _ subtitle: String, _ on: Bool, _ ink: Ink) -> some View {
        HStack(spacing: PUI.Space.m + 2) {
            ZStack {
                Circle().strokeBorder(on ? AppAccent.mittari.color : ink.tertiary, lineWidth: on ? 5 : 1.2)
            }
            .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(PUI.Font.body).foregroundStyle(ink.primary)
                Text(subtitle).font(PUI.Font.caption).foregroundStyle(ink.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, PUI.Space.l)
        .frame(height: 44)
    }

    private func slider(_ v: Double, _ text: String, _ color: Color) -> some View {
        HStack(spacing: PUI.Space.m) {
            PUISlider(value: .constant(v), in: 0.5...1.0).frame(width: 220)
            ValueText(text)
        }
    }

    private func preview(_ v: Double, _ value: String, _ name: String, _ color: Color, _ ink: Ink) -> some View {
        VStack(spacing: PUI.Space.s) {
            GaugeRing(v, color: color, lineWidth: 5, size: 44) {
                Text(value).font(PUI.Font.label).monospacedDigit().foregroundStyle(ink.primary)
            }
            Text(name).font(PUI.Font.caption).foregroundStyle(ink.secondary)
        }
    }
}

enum MittariSettings {
    static let sections: [SidebarSection] = [
        SidebarSection(nil, [
            SidebarItem("Statistics", symbol: "chart.bar.xaxis", style: .tile(AppAccent.mittari.color))
        ]),
        SidebarSection("Settings", [
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("Menu Bar", symbol: "menubar.rectangle", style: .tile(.blue)),
            SidebarItem("Popover", symbol: "rectangle.stack.fill", style: .tile(.indigo))
        ]),
        SidebarSection("Usage", [
            SidebarItem("Limits", symbol: "gauge.with.dots.needle.67percent", style: .tile(.orange)),
            SidebarItem("Prices", symbol: "dollarsign", style: .tile(.green)),
            SidebarItem("Data", symbol: "folder.fill", style: .tile(.cyan))
        ]),
        SidebarSection(nil, [
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]
}
