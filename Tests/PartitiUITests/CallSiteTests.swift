import SwiftUI
import Testing
@testable import PartitiUI

/// Compile-time checks: the call sites the apps write, in 0.2.0 and 0.3.0 form.
/// Building the views is the test; nothing is drawn.
@MainActor @Suite struct CallSiteTests {
    private struct Section: Identifiable {
        let id: String
        var isEnabled = true
    }

    @Test func reorderableGroup() {
        var sections = [Section(id: "record"), Section(id: "today"), Section(id: "week")]
        let items = Binding(get: { sections }, set: { sections = $0 })
        _ = ReorderableGroup("Sections", footer: "Drag to reorder.", items: items, isOn: \.isEnabled,
                             isLocked: { $0.id == "record" }) { section in
            ReorderableLabel(section.id, symbol: "circle")
        }
        _ = ReorderableGroup(Text(verbatim: "Sections"), items: items, isOn: { _ in .constant(true) }) { section in
            Text(verbatim: section.id)
        }
        _ = ReorderableGroup(items: items, isOn: \.isEnabled) { ReorderableLabel(Text(verbatim: $0.id), subtitle: Text("Shown")) }
        _ = SettingsGroup("Shown") {
            ReorderableRows(items, isOn: \.isEnabled) { _ in ReorderableLabel("Title", subtitle: "Subtitle") }
            SwitchRow("24-hour clock", isOn: .constant(true))
        }
        #expect(sections.count == 3)
    }

    @Test func keyPathSwitchWritesBackIntoTheItems() {
        var sections = [Section(id: "today"), Section(id: "week")]
        let items = Binding(get: { sections }, set: { sections = $0 })
        let rows = ReorderableRows(items, isOn: \.isEnabled) { Text(verbatim: $0.id) }
        let week = rows.isOn(sections[1])
        #expect(week.wrappedValue)
        week.wrappedValue = false
        #expect(sections.map(\.isEnabled) == [true, false])
        // The binding follows the item, not its position.
        sections.swapAt(0, 1)
        #expect(!week.wrappedValue)
    }

    @Test func settingsRows() {
        let name = "Dynamic"
        _ = SettingsRow("Preview") { Text(verbatim: "x") }
        _ = SettingsRow(name, subtitle: name) { EmptyView() }
        _ = SettingsRow("Fan", subtitle: "Left", symbol: "fan.fill", symbolColor: .blue) { ValueText("1200 rpm", width: 60) }
        _ = SwitchRow(Text(verbatim: name), subtitle: nil, symbol: "clock", isOn: .constant(false))
        _ = SwitchRow(name, isOn: .constant(false))
        _ = ValueText(Text(12, format: .number))
        _ = ValueText("\(Int(42))%")
    }

    @Test func sliders() {
        _ = PUISlider(value: .constant(0.5))
        _ = PUISlider(value: .constant(50), in: 0...100)
        _ = PUISlider(value: .constant(50), in: 0...100, ticks: 5)
        _ = PUISlider(value: .constant(50), in: 0...100, step: 5)
        _ = PUISlider(value: .constant(50), in: 0...100, step: 5, ticks: 5) { editing in _ = editing }
    }

    @Test func popUpMenus() {
        enum Unit: Hashable { case celsius, fahrenheit }
        _ = PopUpMenu("Sensor", symbol: "thermometer.medium") { Button("CPU") {} }
        _ = PopUpMenu(Text(verbatim: "Sensor")) { Button("CPU") {} }
        _ = PopUpMenu(selection: .constant(Unit.celsius), options: [(.celsius, "Celsius"), (.fahrenheit, "Fahrenheit")])
        let named: [(value: Int, title: String)] = [(1, "One"), (2, "Two")]
        _ = PopUpMenu(selection: .constant(1), options: named, symbol: "number")
        _ = Menu("More") { PopUpOptions([(1, Text("One"))], selection: .constant(1)) }
    }

    @Test func settingsWindowAndAbout() {
        let sections = [SidebarSection(nil, [SidebarItem("General", symbol: "gearshape", style: .tile(.gray))])]
        _ = SettingsWindow(sections: sections, selection: .constant("General")) { Text(verbatim: "pane") }
        _ = SettingsWindow(sections: sections, selection: .constant("General")) { item in
            if item.id != "General" { Button("Delete", role: .destructive) {} }
        } pane: {
            Text(verbatim: "pane")
        }
        _ = SettingsSidebar(sections, selection: .constant("General"))
        _ = SettingsSidebar(sections, selection: .constant("General")) { _ in Button("Rename…") {} }
        let brand = PartitiBrand(accent: .kello, tagline: "", coffeeLine: "", icon: Image(systemName: "clock"))
        _ = AboutPane(brand: brand, version: "1.0", checksAutomatically: .constant(true),
                      onCheckForUpdates: {}, onBuyMeACoffee: {})
        _ = AboutPane(brand: brand, version: "1.0", checksAutomatically: .constant(true),
                      onCheckForUpdates: {}, canCheckForUpdates: false, onBuyMeACoffee: {})
        _ = PopoverFooter(onSettings: {}, onCheckForUpdates: {}, canCheckForUpdates: false, onBuyMeACoffee: {})
    }
}
