import SwiftUI
import PartitiUI

/// Tuuli's thermal scale, kept as a domain palette.
enum Heat {
    static func color(_ t: Double) -> Color {
        switch t {
        case ..<50: Color(red: 0.25, green: 0.72, blue: 0.85)
        case ..<65: Color(red: 0.30, green: 0.75, blue: 0.55)
        case ..<80: Color(red: 0.96, green: 0.66, blue: 0.25)
        default: Color(red: 0.95, green: 0.38, blue: 0.36)
        }
    }
    static func mood(_ t: Double) -> String {
        switch t {
        case ..<50: "Cool"
        case ..<65: "Calm"
        case ..<80: "Warm"
        default: "Hot"
        }
    }
}

enum TuuliData {
    static let history: [Double] = [58, 59, 59, 61, 63, 62, 60, 59, 58, 58, 60, 63, 66, 68, 67, 65, 63, 62, 61, 62, 63, 64, 66, 65, 64, 63, 63, 64, 65, 64]
    static let sensors: [(String, Double)] = [("CPU Hottest", 64), ("GPU Hottest", 58), ("SSD", 41), ("Battery", 33)]
    static let fans: [(String, Int, Double)] = [("Left fan", 2210, 0.28), ("Right fan", 2140, 0.27)]
    static let curve: [(Double, Double)] = [(50, 0), (65, 30), (80, 70), (90, 100)]
}

/// A small area chart with a line, for the popover hero.
struct Sparkline: View {
    let values: [Double]
    let color: Color
    var body: some View {
        GeometryReader { geo in
            let lo = (values.min() ?? 0) - 2, hi = (values.max() ?? 1) + 2
            let pts = values.enumerated().map { i, v in
                CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(values.count - 1),
                        y: geo.size.height * (1 - CGFloat((v - lo) / (hi - lo))))
            }
            let line = smooth(pts)
            ZStack {
                closed(line, geo.size).fill(LinearGradient(colors: [color.opacity(0.28), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                line.stroke(color, style: StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                if let last = pts.last {
                    Circle().fill(color).frame(width: 6, height: 6).position(last)
                    Circle().stroke(Color.white, lineWidth: 1.5).frame(width: 6, height: 6).position(last)
                }
            }
        }
    }
}

func closed(_ line: Path, _ size: CGSize) -> Path {
    var area = line
    area.addLine(to: CGPoint(x: size.width, y: size.height))
    area.addLine(to: CGPoint(x: 0, y: size.height))
    area.closeSubpath()
    return area
}

func smooth(_ pts: [CGPoint]) -> Path {
    var p = Path()
    guard let first = pts.first else { return p }
    p.move(to: first)
    for i in 1..<pts.count {
        let p0 = pts[max(i - 2, 0)], p1 = pts[i - 1], p2 = pts[i], p3 = pts[min(i + 1, pts.count - 1)]
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        p.addCurve(to: p2, control1: c1, control2: c2)
    }
    return p
}

// MARK: - Popover

struct TuuliPopover: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        let accent = AppAccent.tuuli
        PopoverScaffold {
            PopoverHeader(icon: Assets.icon(.tuuli), name: "Tuuli") {
                HeaderStatus("Power Adapter", symbol: "bolt.fill")
            }
        } content: {
            // Hero
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.m) {
                    SectionHeader("CPU Hottest") { Text("last 5 min") }
                    HStack(alignment: .bottom, spacing: PUI.Space.l) {
                        VStack(alignment: .leading, spacing: PUI.Space.xxs) {
                            BigNumber("64°")
                            Badge(Heat.mood(64), color: Heat.color(64))
                        }
                        Sparkline(values: TuuliData.history, color: accent.color)
                            .frame(height: 48)
                            .padding(.bottom, PUI.Space.xxs)
                    }
                }
            }
            // Temperatures
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.xs) {
                    SectionHeader("Temperatures")
                    ForEach(TuuliData.sensors, id: \.0) { s in
                        HStack(spacing: PUI.Space.m) {
                            Circle().fill(Heat.color(s.1)).frame(width: 7, height: 7).frame(width: 16)
                            Text(s.0).font(PUI.Font.body).foregroundStyle(ink.primary)
                            Spacer()
                            Text("\(Int(s.1))°").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                        }
                        .frame(height: PUI.Control.small)
                    }
                }
            }
            // Fans
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.xs) {
                    SectionHeader("Fan speeds") { Text("2 fans") }
                    ForEach(TuuliData.fans, id: \.0) { f in
                        HStack(spacing: PUI.Space.m) {
                            RowSymbol("fan.fill", color: accent.legible(scheme))
                            Text(f.0).font(PUI.Font.body).foregroundStyle(ink.primary).frame(width: 72, alignment: .leading)
                            Meter(f.2, height: 4)
                            Text(verbatim: "\(f.1) rpm").font(PUI.Font.body).monospacedDigit().foregroundStyle(ink.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .frame(height: PUI.Control.small)
                    }
                }
            }
            // Mode
            Card {
                VStack(alignment: .leading, spacing: PUI.Space.m) {
                    SectionHeader("Mode") { Text("Fans held at 28%").monospacedDigit() }
                    let modes: [(String, String)] = [
                        ("System", "apple.logo"), ("Auto Boost", "arrow.up.circle"),
                        ("Curve", "point.topleft.down.to.point.bottomright.curvepath"), ("Manual", "slider.horizontal.3"),
                        ("Quiet", "moon"), ("Rendering", "flame")
                    ]
                    Grid(horizontalSpacing: PUI.Space.s, verticalSpacing: PUI.Space.s) {
                        ForEach(0..<3, id: \.self) { r in
                            GridRow {
                                ForEach(0..<2, id: \.self) { c in
                                    let m = modes[r * 2 + c]
                                    Chip(m.0, symbol: m.1, active: m.0 == "Curve") {}
                                }
                            }
                        }
                    }
                }
            }
        } footer: {
            SampleFooter.make()
        }
    }
}

// MARK: - Settings: Curve

struct CurveChart: View {
    let points: [(Double, Double)]
    let now: Double
    @Environment(\.colorScheme) private var scheme
    @Environment(\.puiAccent) private var accent

    var body: some View {
        let ink = Ink(scheme)
        let xs: ClosedRange<Double> = 20...110
        GeometryReader { geo in
            let left: CGFloat = 44, bottom: CGFloat = 22, top: CGFloat = 8, right: CGFloat = 8
            let w = geo.size.width - left - right, h = geo.size.height - bottom - top
            let px = { (t: Double) -> CGFloat in left + w * CGFloat((t - xs.lowerBound) / (xs.upperBound - xs.lowerBound)) }
            let py = { (p: Double) -> CGFloat in top + h * (1 - CGFloat(p / 100)) }
            let pts = points.map { CGPoint(x: px($0.0), y: py($0.1)) }
            let full = [CGPoint(x: px(20), y: py(0))] + pts + [CGPoint(x: px(110), y: py(100))]
            ZStack(alignment: .topLeading) {
                // grid
                ForEach([0, 25, 50, 75, 100], id: \.self) { p in
                    Path { $0.move(to: CGPoint(x: left, y: py(Double(p)))); $0.addLine(to: CGPoint(x: left + w, y: py(Double(p)))) }
                        .stroke(ink.hairline, lineWidth: 1)
                    Text("\(p)%").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.tertiary)
                        .frame(width: left - 8, alignment: .trailing)
                        .position(x: (left - 8) / 2, y: py(Double(p)))
                }
                ForEach([20, 40, 60, 80, 100], id: \.self) { t in
                    Text("\(t)°").font(PUI.Font.caption).monospacedDigit().foregroundStyle(ink.tertiary)
                        .position(x: px(Double(t)), y: top + h + 13)
                }
                // area and line
                Path { p in
                    p.move(to: full[0])
                    for q in full.dropFirst() { p.addLine(to: q) }
                    p.addLine(to: CGPoint(x: px(110), y: py(0)))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [accent.color.opacity(0.30), accent.color.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                Path { p in
                    p.move(to: full[0])
                    for q in full.dropFirst() { p.addLine(to: q) }
                }
                .stroke(accent.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                // now marker
                let nx = px(now)
                Path { $0.move(to: CGPoint(x: nx, y: top)); $0.addLine(to: CGPoint(x: nx, y: top + h)) }
                    .stroke(Heat.color(now), style: StrokeStyle(lineWidth: 1.25, dash: [3, 3]))
                Text("Now \(Int(now))°")
                    .font(PUI.Font.badge).monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, PUI.Space.s).frame(height: 16)
                    .background(Capsule().fill(PUI.legible(Heat.color(now), scheme)))
                    .position(x: nx, y: top + 10)
                // points
                ForEach(pts.indices, id: \.self) { i in
                    let selected = i == 1
                    ZStack {
                        if selected { Circle().fill(accent.color.opacity(0.22)).frame(width: 28, height: 28) }
                        Circle().fill(Color.white).frame(width: selected ? 16 : 13, height: selected ? 16 : 13)
                        Circle().stroke(accent.color, lineWidth: 2.5).frame(width: selected ? 16 : 13, height: selected ? 16 : 13)
                    }
                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
                    .position(pts[i])
                }
                // tooltip for the selected point
                Text("65° · 30%")
                    .font(PUI.Font.label).monospacedDigit()
                    .foregroundStyle(ink.primary)
                    .padding(.horizontal, PUI.Space.m).frame(height: 22)
                    .puiGlass(Capsule())
                    .position(x: pts[1].x - 4, y: pts[1].y - 26)
            }
        }
    }
}

struct TuuliCurvePane: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ink = Ink(scheme)
        let accent = AppAccent.tuuli
        SettingsPane {
            PaneHeader("Curve", subtitle: "Fan speed follows the sensor along the curve. At 0% the system takes over, so fans can still idle.",
                       symbol: "point.topleft.down.to.point.bottomright.curvepath", color: accent.color) {
                Badge("Active", color: accent.color)
            }
        } content: {
            SettingsGroup("Curve", footer: "Drag the points to shape the curve.") {
                VStack(spacing: PUI.Space.m) {
                    HStack {
                        Text("Follows").font(PUI.Font.body).foregroundStyle(ink.primary)
                        PopUpField("CPU Hottest", symbol: "thermometer.medium")
                        Spacer()
                        Button { } label: { Label("Add Point", systemImage: "plus").labelStyle(TightLabelStyle()) }
                            .buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
                        Button { } label: { Label("Values", systemImage: "list.bullet").labelStyle(TightLabelStyle()) }
                            .buttonStyle(SecondaryButtonStyle(height: PUI.Control.small))
                    }
                    CurveChart(points: TuuliData.curve, now: 64)
                        .frame(height: 250)
                }
                .padding(PUI.Space.l)
            }
            SettingsGroup("Behavior") {
                SettingsRow("Ramp up over", subtitle: "Fans speed up gradually instead of jumping.") { StepperField(value: "5 seconds") }
            }
            SettingsGroup("Power") {
                SettingsRow("Same settings on power adapter and battery") {
                    HStack(spacing: PUI.Space.m) {
                        Text("Different on battery").font(PUI.Font.callout).foregroundStyle(ink.secondary)
                        Toggle("", isOn: .constant(false)).toggleStyle(PUISwitchStyle()).labelsHidden()
                    }
                }
            }
        }
    }
}

enum TuuliSettings {
    static let sections: [SidebarSection] = [
        SidebarSection(nil, [
            SidebarItem("Overview", symbol: "chart.xyaxis.line", style: .tile(AppAccent.tuuli.color)),
            SidebarItem("Sensors", symbol: "thermometer.medium", style: .tile(.orange))
        ]),
        SidebarSection("Modes", [
            SidebarItem("System", symbol: "apple.logo", style: .plain),
            SidebarItem("Auto Boost", symbol: "arrow.up.circle", style: .plain),
            SidebarItem("Curve", symbol: "point.topleft.down.to.point.bottomright.curvepath", style: .plain, checked: true),
            SidebarItem("Manual", symbol: "slider.horizontal.3", style: .plain),
            SidebarItem("Quiet", symbol: "moon", style: .plain),
            SidebarItem("Rendering", symbol: "flame", style: .plain),
            SidebarItem("Add Mode", symbol: "plus", style: .plain)
        ]),
        SidebarSection(nil, [
            SidebarItem("Alerts", symbol: "bell.fill", style: .tile(.red)),
            SidebarItem("Menu Bar", symbol: "menubar.rectangle", style: .tile(.blue)),
            SidebarItem("Logging", symbol: "doc.text.fill", style: .tile(.brown)),
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]
}
