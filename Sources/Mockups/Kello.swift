import SwiftUI
import PartitiUI

/// Calendar colors, as the system draws them in each scheme.
enum Cal {
    case blue, green, cyan, orange, purple, red

    func color(_ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch self {
        case .blue: return dark ? Color(red: 0.04, green: 0.52, blue: 1.00) : Color(red: 0.00, green: 0.48, blue: 1.00)
        case .green: return dark ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(red: 0.20, green: 0.74, blue: 0.33)
        case .cyan: return dark ? Color(red: 0.39, green: 0.82, blue: 1.00) : Color(red: 0.12, green: 0.64, blue: 0.87)
        case .orange: return dark ? Color(red: 1.00, green: 0.62, blue: 0.04) : Color(red: 1.00, green: 0.58, blue: 0.00)
        case .purple: return dark ? Color(red: 0.75, green: 0.35, blue: 0.95) : Color(red: 0.69, green: 0.32, blue: 0.87)
        case .red: return dark ? Color(red: 1.00, green: 0.27, blue: 0.23) : Color(red: 1.00, green: 0.23, blue: 0.19)
        }
    }
}

enum KelloMonth {
    static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    static let dots: [Int: [Cal]] = [
        1: [.blue], 2: [.green, .orange], 3: [.blue], 4: [.purple, .blue],
        7: [.blue, .green], 8: [.green, .cyan], 9: [.blue], 10: [.green, .red], 11: [.blue],
        14: [.blue, .green, .cyan], 15: [.green], 16: [.blue, .green, .orange], 17: [.cyan], 18: [.blue, .red],
        21: [.blue, .green], 22: [.green, .cyan], 23: [.blue, .orange], 24: [.green, .cyan, .purple], 25: [.blue], 26: [.red],
        28: [.blue, .green], 29: [.blue, .cyan], 30: [.blue, .green, .red], 101: [.purple, .blue], 102: [.green]
    ]
    /// (day, in month, key for dots)
    static let cells: [(Int, Bool, Int)] = {
        var c: [(Int, Bool, Int)] = [(31, false, 0)]
        c += (1...30).map { ($0, true, $0) }
        c += (1...4).map { ($0, false, 100 + $0) }
        return c
    }()
}

struct KelloPopover: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        let accent = AppAccent.kello
        PopoverScaffold(width: PUI.Popover.compact) {
            // Month title doubles as the header.
            HStack(spacing: 0) {
                (Text("September ").font(PUI.Font.paneTitle).foregroundStyle(ink.primary)
                 + Text("2026").font(.system(size: 15)).foregroundStyle(ink.secondary))
                    .monospacedDigit()
                Spacer()
                GlassCapsule {
                    IconButton("chevron.left") {}
                    Text("Today").font(.system(size: 11, weight: .semibold)).foregroundStyle(accent.legible(scheme))
                        .padding(.horizontal, PUI.Space.xs)
                    IconButton("chevron.right") {}
                }
            }
            .padding(.leading, PUI.Space.xs)
            .frame(height: PUI.Control.small)
        } content: {
            grid(ink, accent)
            PopoverToolbar {
                SegmentedPill([("Agenda", "Agenda"), ("Reminders", "Reminders")], selection: .constant("Agenda"))
            } trailing: {
                GlassCapsule {
                    IconButton("magnifyingglass") {}
                    IconButton("pin") {}
                    IconButton("plus") {}
                }
            }
            agenda(ink, accent)
                .frame(height: 300, alignment: .top)
                .clipped()
                .mask(VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 44)
                })
        } footer: {
            SampleFooter.make()
        }
    }

    private func grid(_ ink: Ink, _ accent: AppAccent) -> some View {
        let cellW: CGFloat = 32
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(KelloMonth.weekdays.indices, id: \.self) { i in
                    Text(KelloMonth.weekdays[i]).font(PUI.Font.badge)
                        .foregroundStyle(i >= 5 ? ink.tertiary : ink.secondary)
                        .frame(width: cellW, height: 18)
                }
            }
            ForEach(0..<5, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { c in
                        let cell = KelloMonth.cells[r * 7 + c]
                        dayCell(cell, weekend: c >= 5, ink, accent).frame(width: cellW, height: 27)
                    }
                }
            }
        }
        .padding(.horizontal, PUI.Space.s)
        .padding(.top, PUI.Space.xs)
        .padding(.bottom, PUI.Space.s)
        .frame(maxWidth: .infinity)
        .puiSurface()
    }

    private func dayCell(_ cell: (Int, Bool, Int), weekend: Bool, _ ink: Ink, _ accent: AppAccent) -> some View {
        let today = cell.1 && cell.0 == 30
        let dots = KelloMonth.dots[cell.2] ?? []
        return VStack(spacing: 2) {
            ZStack {
                if today {
                    Circle().fill(LinearGradient(colors: [PUI.mix(accent.color, with: .white, by: 0.12), PUI.mix(accent.color, with: .black, by: 0.08)],
                                                 startPoint: .top, endPoint: .bottom))
                        .shadow(color: accent.color.opacity(0.45), radius: 3, y: 1)
                }
                Text("\(cell.0)")
                    .font(.system(size: 12, weight: today ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(today ? .white : (cell.1 ? (weekend ? ink.secondary : ink.primary) : ink.quaternary))
            }
            .frame(width: 20, height: 20)
            HStack(spacing: 1.5) {
                ForEach(dots.indices, id: \.self) { i in
                    Circle().fill(dots[i].color(scheme)).frame(width: 3, height: 3)
                }
            }
            .frame(height: 3)
            .opacity(cell.1 ? 1 : 0.4)
        }
    }

    private func agenda(_ ink: Ink, _ accent: AppAccent) -> some View {
        VStack(alignment: .leading, spacing: PUI.Space.m) {
            nextUp(ink, accent)
            SectionHeader("Today") { Text("4 events") }
                .padding(.horizontal, PUI.Space.xs)
                .padding(.top, PUI.Space.xs)
            VStack(spacing: PUI.Space.xs) {
                event("Standup", "9:30 – 9:45", "Team room", .blue, ink, past: true)
                nowMarker(ink)
                event("Design review", "11:00 – 11:45", "Google Meet", .blue, ink, video: true)
                event("Lunch with Sara", "13:00 – 14:00", "Trattoria da Enzo", .green, ink)
                event("Dentist", "17:30 – 18:15", "Via Roma 12", .red, ink)
            }
            SectionHeader("Tomorrow") { Text("2 events") }
                .padding(.horizontal, PUI.Space.xs)
                .padding(.top, PUI.Space.xs)
            VStack(spacing: PUI.Space.xs) {
                event("Team offsite", "All day", "Lisbon", .purple, ink)
                event("Call with Marco", "10:00 – 10:30", "Zoom", .orange, ink, video: true)
            }
        }
    }

    private func nextUp(_ ink: Ink, _ accent: AppAccent) -> some View {
        let cal = Cal.blue.color(scheme)
        return VStack(alignment: .leading, spacing: PUI.Space.xs) {
            HStack(spacing: PUI.Space.s) {
                Circle().fill(cal).frame(width: 6, height: 6)
                Text("NEXT UP").font(PUI.Font.badge).tracking(PUI.Font.badgeTracking).foregroundStyle(PUI.legible(cal, scheme))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.system(size: 9, weight: .semibold))
                    Text("in 19m").font(PUI.Font.badge).monospacedDigit()
                }
                .foregroundStyle(ink.secondary)
                .padding(.horizontal, PUI.Space.s)
                .frame(height: 16)
                .background(Capsule().fill(ink.fill))
            }
            Text("Design review").font(PUI.Font.headline).foregroundStyle(ink.primary)
                .padding(.top, PUI.Space.xxs)
            Text("11:00 – 11:45 · Product team").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
            HStack(spacing: PUI.Space.xs) {
                Image(systemName: "video.fill").font(.system(size: 9))
                Text("Google Meet").font(PUI.Font.caption)
                Spacer()
                JoinButton {}
            }
            .foregroundStyle(ink.secondary)
            .padding(.top, PUI.Space.xs)
        }
        .padding(PUI.Space.m + 2)
        .puiSurface(tint: cal)
    }

    private func nowMarker(_ ink: Ink) -> some View {
        HStack(spacing: PUI.Space.s) {
            Circle().fill(ink.red).frame(width: 6, height: 6).shadow(color: ink.red.opacity(0.6), radius: 3)
            LinearGradient(colors: [ink.red, ink.red.opacity(0.1)], startPoint: .leading, endPoint: .trailing).frame(height: 1)
            Text("in 19m").font(PUI.Font.badge).monospacedDigit().foregroundStyle(ink.red)
        }
        .padding(.horizontal, PUI.Space.xs)
        .frame(height: 12)
    }

    private func event(_ title: String, _ time: String, _ detail: String, _ cal: Cal, _ ink: Ink, past: Bool = false, video: Bool = false) -> some View {
        let c = cal.color(scheme)
        return HStack(spacing: PUI.Space.m) {
            Capsule().fill(c).frame(width: 3)
                .padding(.vertical, 1)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(PUI.Font.headline).foregroundStyle(ink.primary).lineLimit(1)
                    Spacer(minLength: PUI.Space.s)
                    Text(time).font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.secondary)
                }
                HStack(spacing: 3) {
                    if video { Image(systemName: "video.fill").font(.system(size: 8)) }
                    Text(detail).font(PUI.Font.caption).lineLimit(1)
                }
                .foregroundStyle(ink.secondary)
            }
        }
        .padding(.leading, PUI.Space.s)
        .padding(.trailing, PUI.Space.m)
        .padding(.vertical, PUI.Space.s)
        .frame(height: 40)
        .background(RoundedRectangle(cornerRadius: PUI.Radius.row, style: .continuous).fill(c.opacity(scheme == .dark ? 0.12 : 0.08)))
        .opacity(past ? 0.5 : 1)
    }
}

// MARK: - Settings: Calendars

struct KelloCalendarsPane: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        SettingsPane {
            PaneHeader("Calendars", subtitle: "Choose which calendars and reminder lists appear in the menu bar.",
                       symbol: "calendar", color: .red)
        } content: {
            SettingsGroup("Holidays", footer: "Days with an event in this calendar get a red number in the grid, and the holiday's name shows above that day's agenda.") {
                SettingsRow("Holidays calendar") { PopUpField("Italian Holidays", symbol: "star.fill") }
            }
            SettingsGroup("iCloud") {
                calendar("Personal", .green, true, ink)
                calendar("Family", .orange, true, ink)
                calendar("Birthdays", .purple, false, ink)
            }
            SettingsGroup("Google") {
                calendar("Work", .blue, true, ink)
                calendar("Product team", .cyan, true, ink)
            }
        }
    }

    private func calendar(_ name: String, _ cal: Cal, _ on: Bool, _ ink: Ink) -> some View {
        let c = cal.color(scheme)
        return HStack(spacing: PUI.Space.m + 2) {
            Circle().fill(LinearGradient(colors: [PUI.mix(c, with: .white, by: 0.15), c], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                .frame(width: 12, height: 12)
            Text(name).font(PUI.Font.body).foregroundStyle(ink.primary)
            Spacer()
            Toggle("", isOn: .constant(on)).toggleStyle(PUISwitchStyle()).labelsHidden()
        }
        .padding(.horizontal, PUI.Space.l)
        .frame(height: 38)
    }
}

enum KelloSettings {
    static let sections: [SidebarSection] = [
        SidebarSection(nil, [
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("Calendars", symbol: "calendar", style: .tile(.red)),
            SidebarItem("Notifications", symbol: "bell.badge.fill", style: .tile(.orange)),
            SidebarItem("Menu Bar", symbol: "menubar.rectangle", style: .tile(.blue)),
            SidebarItem("Time Zones", symbol: "globe", style: .tile(.indigo)),
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]
}

struct AboutScreen: View {
    let accent: AppAccent
    let version: String
    var body: some View {
        AboutPane(brand: Brands.brand(accent), version: version, checksAutomatically: .constant(true),
                  onCheckForUpdates: {}, onBuyMeACoffee: {})
            .padding(.top, 44)
            .padding(.horizontal, PUI.Space.xxl)
    }
}
