import SwiftUI

/// Partiti UI: the shared design tokens of the Partiti menu bar apps.
/// Every measure in the apps should come from here rather than from a literal.
public enum PUI {

    // MARK: Spacing

    /// The spacing scale. Everything sits on a 2/4 pt grid.
    public enum Space {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 6
        public static let m: CGFloat = 8
        public static let l: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let xxl: CGFloat = 24

        /// All steps, smallest first, for catalogs and previews.
        public static let scale: [(name: String, value: CGFloat)] = [
            ("xxs", xxs), ("xs", xs), ("s", s), ("m", m), ("l", l), ("xl", xl), ("xxl", xxl)
        ]
    }

    // MARK: Radii

    /// Corner radii. Always drawn with the `.continuous` style.
    public enum Radius {
        /// Content cards in a popover and settings groups.
        public static let card: CGFloat = 12
        /// Grouped rows inside a card, permission and provider groups.
        public static let group: CGFloat = 10
        /// A single row, hover highlights and footer buttons.
        public static let row: CGFloat = 8
        /// Icon tiles round at 27% of their side, like System Settings.
        public static func tile(_ side: CGFloat) -> CGFloat { (side * 0.27).rounded() }
        /// The system popover, concentric with a card inset by the popover margin.
        public static let popover: CGFloat = card + Popover.margin
        /// The settings window.
        public static let window: CGFloat = 20

        /// The radius of a shape inset by `inset` inside a shape of radius `outer`,
        /// so both corners share a center and the gap between them stays even.
        public static func concentric(_ outer: CGFloat, inset: CGFloat) -> CGFloat {
            max(outer - inset, 0)
        }
    }

    // MARK: Controls

    /// Control heights.
    public enum Control {
        /// Round glass buttons, toolbar capsules, the Today pill.
        public static let small: CGFloat = 22
        /// Segmented controls, fields, secondary buttons.
        public static let regular: CGFloat = 28
        /// The primary action and the Coffee capsule.
        public static let large: CGFloat = 34
        /// SF Symbol size inside small controls.
        public static let smallSymbol: CGFloat = 11
    }

    // MARK: Popover

    /// Popover geometry.
    public enum Popover {
        /// Tuuli, Kaiku, Kiito, Mittari.
        public static let regular: CGFloat = 320
        /// Kello, where the month grid sets the width.
        public static let compact: CGFloat = 260
        /// Outer margin of the popover content.
        public static let margin: CGFloat = 12
        /// Gap between cards.
        public static let cardGap: CGFloat = 8
        /// Padding inside a card.
        public static let cardPadding: CGFloat = 12
        /// Gap between rows inside a card.
        public static let rowGap: CGFloat = 4
        /// Height of the popover header.
        public static let headerHeight: CGFloat = 22
        /// Size of the app icon in the header.
        public static let headerIcon: CGFloat = 16
    }

    // MARK: Windows

    /// Settings window geometry.
    public enum Window {
        /// Settings only: Kaiku, Kiito, Kello.
        public static let settings = CGSize(width: 720, height: 520)
        /// Minimum size of a settings-only window.
        public static let settingsMin = CGSize(width: 640, height: 440)
        /// Settings with a dashboard page: Tuuli, Mittari.
        public static let dashboard = CGSize(width: 1040, height: 700)
        /// Minimum size of a window with a dashboard page.
        public static let dashboardMin = CGSize(width: 900, height: 580)
        /// Ideal sidebar width.
        public static let sidebar: CGFloat = 200
        /// Narrowest sidebar before titles truncate.
        public static let sidebarMin: CGFloat = 180
        /// Sidebar icon tiles.
        public static let sidebarTile: CGFloat = 22
        /// Pane header icon tile.
        public static let paneTile: CGFloat = 40
        /// Readable width of a settings form in wide windows.
        public static let formMaxWidth: CGFloat = 640
    }

    // MARK: Type

    /// The eight-step type scale, in fixed points: menu bar popovers don't follow Dynamic Type.
    public enum Font {
        /// The main number of a popover. 30 light rounded, monospaced digits.
        public static let display = SwiftUI.Font.system(size: 30, weight: .light, design: .rounded).monospacedDigit()
        /// Page titles and the app name in About. 22 semibold.
        public static let title = SwiftUI.Font.system(size: 22, weight: .semibold)
        /// Secondary values and stat tiles. 20 semibold rounded, monospaced digits.
        public static let stat = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit()
        /// Settings pane header. 15 semibold.
        public static let paneTitle = SwiftUI.Font.system(size: 15, weight: .semibold)
        /// App name in the popover, row titles. 13 semibold.
        public static let headline = SwiftUI.Font.system(size: 13, weight: .semibold)
        /// Row text. 13 regular.
        public static let body = SwiftUI.Font.system(size: 13)
        /// Footer buttons and secondary text. 12 regular.
        public static let callout = SwiftUI.Font.system(size: 12)
        /// Card and section labels, shown secondary. 11 medium.
        public static let label = SwiftUI.Font.system(size: 11, weight: .medium)
        /// Notes and details, shown secondary. 10 regular.
        public static let caption = SwiftUI.Font.system(size: 10)
        /// Badges and counters, uppercased with 6% tracking. 10 semibold.
        public static let badge = SwiftUI.Font.system(size: 10, weight: .semibold)
        /// Tracking that goes with `badge`.
        public static let badgeTracking: CGFloat = 0.6
        /// The status item text: menu bar font with monospaced digits.
        public static let menuBar = SwiftUI.Font.system(size: 13, weight: .medium).monospacedDigit()

        /// The scale in order, for catalogs and previews.
        public static let scale: [(name: String, spec: String, font: SwiftUI.Font)] = [
            ("display", "30 light rounded", display),
            ("title", "22 semibold", title),
            ("stat", "20 semibold rounded", stat),
            ("paneTitle", "15 semibold", paneTitle),
            ("headline", "13 semibold", headline),
            ("body", "13 regular", body),
            ("callout", "12 regular", callout),
            ("label", "11 medium", label),
            ("caption", "10 regular", caption),
            ("badge", "10 semibold caps", badge)
        ]
    }

    // MARK: Motion

    /// Motion: short springs for state, quick ease-out for hover, fades with Reduce Motion.
    public enum Motion {
        /// The spring for state changes, or a short fade when Reduce Motion is on.
        public static func spring(reduceMotion: Bool) -> Animation {
            reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.32, bounce: 0.12)
        }
        /// Hover feedback: fast enough to feel direct.
        public static let hover = Animation.easeOut(duration: 0.12)
    }

    // MARK: Fixed colors

    /// The Buy Me a Coffee yellow, used only on the Coffee capsule.
    public static let coffee = Color(red: 1, green: 0.871, blue: 0)
}

extension Color {
    /// A color from a 0xRRGGBB literal. Internal so it never collides with an app's own helper.
    init(rgb hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity)
    }
}
