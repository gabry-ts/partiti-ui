import SwiftUI

/// The look of a status item: 22 pt tall, parts in the menu bar font with monospaced digits,
/// 4 pt between symbol and reading, a capsule behind it while its popover is open.
/// Use it where SwiftUI draws the status item, and as the reference for an `NSStatusItem` button.
public struct MenuBarItem<Content: View>: View {
    var highlighted: Bool
    var color: Color
    let content: Content

    public init(highlighted: Bool = false, color: Color = .white, @ViewBuilder _ content: () -> Content) {
        self.highlighted = highlighted
        self.color = color
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: PUI.Space.xs) { content }
            .font(PUI.Font.menuBar)
            .foregroundStyle(color)
            .padding(.horizontal, PUI.Space.s + 1)
            .frame(height: PUI.Control.small)
            .background(Capsule().fill(highlighted ? color.opacity(0.24) : .clear))
    }
}

/// A status item symbol, regular weight at the menu bar size.
public struct MenuBarSymbol: View {
    let name: String

    public init(_ name: String) { self.name = name }

    public var body: some View {
        Image(systemName: name).font(.system(size: 13, weight: .regular))
    }
}

/// A small ring for the menu bar: 13 pt, 2.2 pt stroke, track at 30% of the foreground.
public struct MenuBarRing: View {
    let value: Double
    var color: Color?

    public init(_ value: Double, color: Color? = nil) {
        self.value = value
        self.color = color
    }

    public var body: some View {
        ZStack {
            Circle().stroke(.foreground.opacity(0.3), lineWidth: 2.2)
            Circle().trim(from: 0, to: value)
                .stroke(color.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.foreground), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 13, height: 13)
    }
}

/// The pill for an active state such as recording: 16 pt, not template, in the accent,
/// so it stands out from the monochrome items around it. Gray while paused.
public struct MenuBarPill: View {
    let text: String
    var paused: Bool
    @Environment(\.puiAccent) private var accent

    public init(_ text: String, paused: Bool = false) {
        self.text = text
        self.paused = paused
    }

    public var body: some View {
        HStack(spacing: PUI.Space.xs) {
            if paused {
                Image(systemName: "pause.fill").font(.system(size: 7, weight: .bold))
            } else {
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }
            Text(text).font(.system(size: 11.5, weight: .semibold).monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, PUI.Space.s)
        .frame(height: 16)
        .background(Capsule().fill(paused ? Color(white: 0.45) : accent.color))
    }
}
