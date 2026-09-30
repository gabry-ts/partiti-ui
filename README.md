# Partiti UI

The shared design language of [Tuuli, Kaiku, Kiito, Mittari and Kello](https://apps.partiti.dev), five free menu bar apps for macOS. It is a small SwiftUI package with the design tokens, the glass materials and the components the apps are built from, so the five of them look like they come from the same hands.

![Tokens and components, light](docs/images/components-light.png)

## Principles

- **The system first.** Glass, controls and forms come from macOS as they are. Only what the system doesn't offer is drawn by hand.
- **One color per app.** The identity color marks primary actions, selection and active state only. Everything else stays neutral.
- **Same skeleton, different content.** Header, content and footer are the same everywhere; what goes inside belongs to each app.
- **Stable numbers.** Every value that changes uses monospaced digits; big numbers use SF Pro Rounded.
- **Light and accessible.** No continuous animation. Reduce Motion, Increase Contrast and Reduce Transparency are respected.

## Requirements

- macOS 14 or later. Liquid Glass is used on macOS 26 and later; see [Glass](#glass).
- Swift 6.2 (Xcode 26) or later.

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gabry-ts/partiti-ui", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [.product(name: "PartitiUI", package: "partiti-ui")])
]
```

In Xcode, use File > Add Package Dependencies… with the same URL and add the `PartitiUI` library to the app target.

A change here reaches five apps, so depend on tagged versions and update deliberately rather than tracking `main`.

## Usage

Set the accent once, at the root of every popover and window. It feeds every Partiti UI component and sets the system tint for native controls.

```swift
import PartitiUI

struct MenuContent: View {
    var body: some View {
        PopoverScaffold {
            PopoverHeader(icon: Image("AppIcon"), name: "Kaiku") {
                GlassCircleButton("folder") { openRecordingsFolder() }
            }
        } content: {
            Card {
                VStack(alignment: .leading, spacing: PUI.Popover.rowGap) {
                    SectionHeader("Recent") { Text("4 calls") }
                    Row("Weekly sync", subtitle: "Today, 9:30 · 28 min",
                        leading: { RowSymbol("text.bubble") },
                        trailing: { EmptyView() })
                }
            }
        } footer: {
            PopoverFooter(
                actions: [.init("Recordings", symbol: "list.bullet.rectangle") { showRecordings() }],
                onSettings: { openSettings() },
                onCheckForUpdates: { updater.checkForUpdates() },
                onBuyMeACoffee: { openURL(coffeeURL) })
        }
        .puiAccent(.kaiku)
    }
}
```

The settings window is a floating sidebar and a pane. Give the window a full-size content view with a transparent title bar so the sidebar runs under the traffic lights.

```swift
struct SettingsView: View {
    @State private var selection = "General"
    @State private var checksAutomatically = true
    @State private var launchAtLogin = false

    let sections = [
        SidebarSection(nil, [
            SidebarItem("General", symbol: "gearshape.fill", style: .tile(.gray)),
            SidebarItem("Recording", symbol: "mic.fill", style: .tile(AppAccent.kaiku.color)),
            SidebarItem("About", symbol: "info", style: .tile(.teal))
        ])
    ]

    var body: some View {
        SettingsWindow(sections: sections, selection: $selection) {
            switch selection {
            case "About":
                AboutPane(
                    brand: PartitiBrand(accent: .kaiku,
                                        tagline: "Record and transcribe your calls",
                                        coffeeLine: "Kaiku is free. If it saves you some notes, you can buy me a coffee.",
                                        icon: Image("AppIcon")),
                    version: "Version 1.2 (34)",
                    checksAutomatically: $checksAutomatically,
                    onCheckForUpdates: { updater.checkForUpdates() },
                    onBuyMeACoffee: { openURL(coffeeURL) })
            default:
                SettingsPane {
                    PaneHeader("General", subtitle: "Startup and menu bar icon.", symbol: "gearshape.fill", color: .gray)
                } content: {
                    SettingsGroup("Startup") {
                        SettingsRow("Launch at login") {
                            Toggle("Launch at login", isOn: $launchAtLogin)
                                .toggleStyle(PUISwitchStyle())
                                .labelsHidden()
                        }
                    }
                }
            }
        }
        .frame(minWidth: PUI.Window.settingsMin.width, minHeight: PUI.Window.settingsMin.height)
        .puiAccent(.kaiku)
    }
}
```

## Tokens

All tokens live under the `PUI` namespace. Measures in the apps should come from here rather than from literals.

### Accents

| App | `AppAccent` | Hex |
| --- | --- | --- |
| Tuuli | `.tuuli` | `#2F7BFF` |
| Kaiku | `.kaiku` | `#E8364F` |
| Kiito | `.kiito` | `#22CBBB` |
| Mittari | `.mittari` | `#F59E0B` |
| Kello | `.kello` | `#4C6EF5` |

`accent.legible(scheme)` deepens the accent by 18% in light mode for text and glyphs. Kiito and Mittari are bright enough that solid fills take a dark label (`prefersDarkLabel`).

Neutral inks (`Ink(scheme).primary`, `.secondary`, `.tertiary`, `.hairline`, `.fill`, and the semantic `.green`, `.orange`, `.red`) are resolved per color scheme, so live views and offscreen renders agree.

### Spacing, radii, controls

| `PUI.Space` | xxs | xs | s | m | l | xl | xxl |
| --- | --- | --- | --- | --- | --- | --- | --- |
| pt | 2 | 4 | 6 | 8 | 12 | 16 | 24 |

| `PUI.Radius` | Value | Used for |
| --- | --- | --- |
| `card` | 12 | Popover cards |
| `group` | 10 | Settings groups, primary button |
| `row` | 8 | Rows, hover highlights, chips |
| `popover` | 24 | The popover, concentric with cards (`card + margin`) |
| `window` | 20 | The settings window |
| `tile(side)` | 27% | Icon tiles |
| `concentric(outer, inset:)` | | A radius inset inside another, sharing its center |

| `PUI.Control` | Height |
| --- | --- |
| `small` | 22: round glass buttons, toolbar capsules |
| `regular` | 28: segmented controls, fields, secondary buttons |
| `large` | 34: the primary action, the Coffee capsule |

Popovers are `PUI.Popover.regular` (320) or `compact` (260, Kello) wide, with a 12 pt margin, 8 pt between cards and 12 pt inside them. Settings windows are `PUI.Window.settings` (720 × 520) or `dashboard` (1040 × 700) for apps with a dashboard page.

### Type

Fixed sizes, because menu bar popovers don't follow Dynamic Type.

| `PUI.Font` | Spec | Used for |
| --- | --- | --- |
| `display` | 30 light rounded, mono digits | The main number of a popover |
| `title` | 22 semibold | Page titles, the app name in About |
| `stat` | 20 semibold rounded, mono digits | Secondary values, stat tiles |
| `paneTitle` | 15 semibold | Settings pane header |
| `headline` | 13 semibold | App name in the popover, row titles |
| `body` | 13 regular | Row text |
| `callout` | 12 regular | Footer buttons, secondary text |
| `label` | 11 medium | Card and section labels |
| `caption` | 10 regular | Notes and details |
| `badge` | 10 semibold caps, 6% tracking | Badges and counters |
| `menuBar` | 13 medium, mono digits | Status item text |

### Motion

`PUI.Motion.spring(reduceMotion:)` for state changes (a short fade with Reduce Motion) and `PUI.Motion.hover` for hover feedback.

## Components

**Popover.** `PopoverScaffold`, `PopoverHeader`, `HeaderStatus`, `PopoverToolbar`, `PopoverFooter` (app actions, Settings…, the ⋯ menu with Check for Updates… and Buy Me a Coffee…, Quit, with ⌘, and ⌘Q), `FooterButton`, `Card`, `SectionHeader`, `Row`, `RowSymbol`, `EmptyState`.

**Controls.** `GlassCircleButton`, `GlassCapsule` with `IconButton`, `SegmentedPill`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `JoinButton`, `CoffeeButton`, `PUISwitchStyle`, `PUISlider`, `PopUpField`, `CheckMark`, `Chip`, `Badge`, `TightLabelStyle`.

**Data.** `Meter`, `GaugeRing`, `BigNumber`, `StatTile`.

**Settings.** `SettingsWindow`, `SettingsSidebar` with `SidebarSection` and `SidebarItem`, `SettingsPane`, `PaneHeader`, `IconTile`, `SettingsGroup`, `SettingsRow`, `AboutPane` with `PartitiBrand`.

**Menu bar.** `MenuBarItem`, `MenuBarSymbol`, `MenuBarRing`, `MenuBarPill`.

**Materials.** `.puiGlass(_:tint:)` for controls, `.puiSurface(...)` for content cards, `.puiHoverHighlight(_:)`, `Hairline`, `Ink` and `Inked`.

Types that would clash with SwiftUI names carry a `PUI` prefix (`PUISwitchStyle`, `PUISlider`); modifiers added to `View` carry a `pui` prefix.

![The five status items](docs/images/menubar-light.png)

## Glass

`.puiGlass` is for controls only; cards use a painted `.puiSurface`, because glass on glass muddies text.

| macOS | `.live` (default) |
| --- | --- |
| 26 and later | The system Liquid Glass (`glassEffect`, interactive, tinted as a wash) |
| 14 and 15 | A thin system material in the same shape, with the painted sheen, hairlines and shadow on top; an opaque window background with Reduce Transparency |

`ImageRenderer` can't draw system glass or AppKit-backed controls such as menus. For offscreen renders, set `.puiGlassRendering(.painted)`: glass is painted in the same shapes, and the footer's ⋯ menu is drawn as its label. Running apps never need it.

On macOS 14, `SettingsGroup` shows its rows without the hairlines between them, since splitting arbitrary content into rows needs macOS 15.

## Regenerating the images

The `Mockups` executable renders mockups of all five apps with `ImageRenderer`, in light and dark, and doubles as a usage reference. It isn't part of the library product, so apps depending on `PartitiUI` never build it.

```sh
swift run Mockups                           # every image, into ./renders
swift run Mockups renders components menubar # only names containing these words
```

The images in `docs/images` come from `components-*` and `menubar-*`.

## License

GPL-3.0. See [LICENSE](LICENSE).
