import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PartitiUI

// Renders the README and site images.
// Usage: swift run Mockups [output-dir] [name-filter ...]   (output defaults to ./renders)
let args = CommandLine.arguments
let outDir = URL(fileURLWithPath: args.count > 1 ? args[1] : "renders")
let filters = Array(args.dropFirst(2))
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

@MainActor
func write<V: View>(_ view: V, _ name: String, scale: CGFloat = 2) {
    if !filters.isEmpty && !filters.contains(where: { name.contains($0) }) { return }
    let r = ImageRenderer(content: view)
    r.scale = scale
    guard let img = r.cgImage else { print("failed", name); return }
    let url = outDir.appendingPathComponent(name + ".png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote", name, img.width, "x", img.height)
}

struct Screen {
    let accent: AppAccent
    let popover: AnyView
    let sections: [SidebarSection]
    let selection: String
    let pane: AnyView
    let window: CGSize
}

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let geo = MenuBarGeometry.measure()

    let screens: [Screen] = [
        Screen(accent: .tuuli, popover: AnyView(TuuliPopover()), sections: TuuliSettings.sections, selection: "Curve",
               pane: AnyView(TuuliCurvePane()), window: PUI.Window.dashboard),
        Screen(accent: .kaiku, popover: AnyView(KaikuPopover()), sections: KaikuSettings.sections, selection: "Transcription",
               pane: AnyView(KaikuTranscriptionPane()), window: PUI.Window.settings),
        Screen(accent: .kiito, popover: AnyView(KiitoPopover()), sections: KiitoSettings.sections, selection: "Default",
               pane: AnyView(KiitoScrollingPane()), window: PUI.Window.settings),
        Screen(accent: .mittari, popover: AnyView(MittariPopover()), sections: MittariSettings.sections, selection: "Limits",
               pane: AnyView(MittariLimitsPane()), window: PUI.Window.dashboard),
        Screen(accent: .kello, popover: AnyView(KelloPopover()), sections: KelloSettings.sections, selection: "Calendars",
               pane: AnyView(KelloCalendarsPane()), window: PUI.Window.settings)
    ]

    for dark in [false, true] {
        let mode = dark ? "dark" : "light"
        write(ComponentsSheet(dark: dark), "components-\(mode)")
        write(MenuBarStrip(dark: dark, geometry: geo), "menubar-\(mode)", scale: 3)

        for s in screens {
            let name = s.accent.rawValue
            let content = s.popover.puiAccent(s.accent).environment(\.colorScheme, dark ? .dark : .light)
            let size = measure(content)
            let popSize = CGSize(width: ceil(size.width), height: ceil(size.height))
            if !dark {
                let cx = geo.center(of: s.accent, width: 720)
                let x = min(max(cx - popSize.width / 2, 10), 720 - 10 - popSize.width)
                print("layout", name, Int(x), Int(popSize.width), Int(cx))
            }
            write(PopoverStage(dark: dark, accent: s.accent, size: popSize, geometry: geo) { content },
                  "\(name)-popover-\(mode)")
            write(WindowStage(dark: dark, accent: s.accent, size: s.window) {
                SettingsWindow(sections: s.sections, selection: .constant(s.selection)) { s.pane }
            }, "\(name)-settings-\(mode)")
        }

        write(WindowStage(dark: dark, accent: .kello, size: PUI.Window.settings) {
            SettingsWindow(sections: KelloSettings.sections, selection: .constant("About")) {
                AboutScreen(accent: .kello, version: "Version 1.2 (34)")
            }
        }, "about-\(mode)")
    }
}
