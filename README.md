# Partiti UI

The shared design language of [Tuuli, Kaiku, Kiito, Mittari and Kello](https://apps.partiti.dev), five free menu bar apps for macOS. A small SwiftUI package with the design tokens, glass materials and components the apps are built from, so the five of them look like they come from the same hands.

![Tokens and components, light](docs/images/components-light.png)

## Install

```swift
dependencies: [
    .package(url: "https://github.com/gabry-ts/partiti-ui", from: "0.3.0")
],
targets: [
    .target(name: "MyApp", dependencies: [.product(name: "PartitiUI", package: "partiti-ui")])
]
```

## Usage

```swift
import PartitiUI

struct MenuContent: View {
    var body: some View {
        PopoverScaffold {
            PopoverHeader(icon: Image("AppIcon"), name: "Kaiku") {
                GlassCircleButton("folder") { openRecordingsFolder() }
            }
        } content: {
            Card { Text("Hello") }
        } footer: {
            PopoverFooter(onSettings: { openSettings() })
        }
        .puiAccent(.kaiku)
    }
}
```

## Components

Popover pieces (`PopoverScaffold`, `PopoverHeader`, `PopoverFooter`, `Card`, `Row`), controls (`GlassCircleButton`, `GlassCapsule`, `SegmentedPill`, `CoffeeButton`, `PUISwitchStyle`, `PUISlider`, `ValueText`, `PopUpMenu`), data views (`Meter`, `GaugeRing`, `BigNumber`, `StatTile`), a full settings window kit (`SettingsWindow`, `SettingsSidebar`, `SettingsPane`, `SettingsRow`, `SwitchRow`, `ReorderableGroup`, `AboutPane`), menu bar items and the glass and surface materials that back them all, plus localization support in English and Italian out of the box.

## What's new in 0.3.0

`ReorderableGroup` lets users choose what is shown and drag it into order, with `Reorder` for the move logic and for fitting a saved order to the items an app knows.
New `SwitchRow`, `ValueText` and `PopUpMenu`; `PUISlider` takes a `step` and `onEditingChanged`, `SettingsRow` a leading symbol, sidebar entries a context menu, footer actions a keyboard shortcut.
A trailing closure on `PopoverFooter` is now the menu items, `SettingsWindow` extends under the title bar by itself, and Check for Updates… can be disabled. Call `window.puiConfigureForSettings()` on the window that hosts it, so the traffic lights sit inside the sidebar.

## License

GPL-3.0. See [LICENSE](LICENSE).
