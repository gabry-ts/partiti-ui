import SwiftUI

/// A capsule meter: 6 pt in cards, 4 pt in rows. Track at 8% of the primary ink.
public struct Meter: View {
    var value: Double
    var color: Color?
    var height: CGFloat
    /// Optional marks, as fractions, drawn as thin notches (thresholds).
    var marks: [Double]
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ value: Double, color: Color? = nil, height: CGFloat = 6, marks: [Double] = []) {
        self.value = value
        self.color = color
        self.height = height
        self.marks = marks
    }

    public var body: some View {
        let c = color ?? accent.color
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [c.opacity(0.85), c], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
                ForEach(marks.indices, id: \.self) { i in
                    Rectangle()
                        .fill(Ink(scheme).secondary.opacity(0.7))
                        .frame(width: 1, height: height + 4)
                        .offset(x: geo.size.width * marks[i] - 0.5)
                }
            }
        }
        .frame(height: height)
    }
}

/// A ring gauge with a 6 pt stroke and an optional center label.
public struct GaugeRing<Center: View>: View {
    var value: Double
    var color: Color?
    var lineWidth: CGFloat
    var size: CGFloat
    let center: Center
    @Environment(\.puiAccent) private var accent
    @Environment(\.colorScheme) private var scheme

    public init(_ value: Double, color: Color? = nil, lineWidth: CGFloat = 6, size: CGFloat = 64, @ViewBuilder center: () -> Center) {
        self.value = value
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.center = center()
    }

    public var body: some View {
        let c = color ?? accent.color
        let f = min(max(value, 0), 1)
        ZStack {
            Circle().stroke(scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: f)
                .stroke(AngularGradient(colors: [c.opacity(0.75), c], center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * f)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center
        }
        .frame(width: size, height: size)
    }
}

public extension GaugeRing where Center == EmptyView {
    init(_ value: Double, color: Color? = nil, lineWidth: CGFloat = 6, size: CGFloat = 64) {
        self.init(value, color: color, lineWidth: lineWidth, size: size) { EmptyView() }
    }
}

/// A big number with an optional unit, in `display` or `stat`.
public struct BigNumber: View {
    let value: String
    var unit: String?
    var font: Font
    var unitFont: Font
    var color: Color?
    @Environment(\.colorScheme) private var scheme

    public init(_ value: String, unit: String? = nil, font: Font = PUI.Font.display,
                unitFont: Font = .system(size: 15, weight: .regular, design: .rounded), color: Color? = nil) {
        self.value = value
        self.unit = unit
        self.font = font
        self.unitFont = unitFont
        self.color = color
    }

    public var body: some View {
        let ink = Ink(scheme)
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(value).font(font).foregroundStyle(color ?? ink.primary)
            if let unit { Text(unit).font(unitFont).foregroundStyle(ink.secondary) }
        }
    }
}

/// A stat tile: label, value in `stat`, detail in caption.
public struct StatTile: View {
    let label: String
    let value: String
    var unit: String?
    var detail: String?
    @Environment(\.colorScheme) private var scheme

    public init(_ label: String, value: String, unit: String? = nil, detail: String? = nil) {
        self.label = label
        self.value = value
        self.unit = unit
        self.detail = detail
    }

    public var body: some View {
        let ink = Ink(scheme)
        VStack(alignment: .leading, spacing: PUI.Space.xxs) {
            Text(label).font(PUI.Font.label).foregroundStyle(ink.secondary)
            BigNumber(value, unit: unit, font: PUI.Font.stat, unitFont: .system(size: 12, weight: .medium, design: .rounded))
            if let detail {
                Text(detail).font(PUI.Font.caption).foregroundStyle(ink.tertiary).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
