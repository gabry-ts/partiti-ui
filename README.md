# Partiti UI

The shared design language of [Tuuli, Kaiku, Kiito, Mittari and Kello](https://apps.partiti.dev), five free menu bar apps for macOS. A small SwiftUI package with the design tokens, glass materials and components the apps are built from, so the five of them look like they come from the same hands.

![Tokens and components, light](docs/images/components-light.png)

## Install

```swift
dependencies: [
    .package(url: "https://github.com/gabry-ts/partiti-ui", from: "0.2.0")
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

Popover pieces (`PopoverScaffold`, `PopoverHeader`, `PopoverFooter`, `Card`, `Row`), controls (`GlassCircleButton`, `GlassCapsule`, `SegmentedPill`, `CoffeeButton`, `PUISwitchStyle`, `PUISlider`), data views (`Meter`, `GaugeRing`, `BigNumber`, `StatTile`), a full settings window kit (`SettingsWindow`, `SettingsSidebar`, `SettingsPane`, `AboutPane`), menu bar items and the glass and surface materials that back them all, plus localization support in English and Italian out of the box.

## License

GPL-3.0. See [LICENSE](LICENSE).
