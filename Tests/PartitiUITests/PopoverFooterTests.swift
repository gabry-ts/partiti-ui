import SwiftUI
import Testing
@testable import PartitiUI

/// Every way the apps build a footer has to keep compiling, and a trailing closure
/// has to be the menu items rather than `onQuit`.
@MainActor @Suite struct PopoverFooterTests {
    @Test func aTrailingClosureIsTheMenuItems() {
        let footer = PopoverFooter(onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {}) {
            Button("Export…") {}
        }
        #expect(footer.menuItems != nil)
    }

    @Test func aTrailingClosureAfterOnQuitIsTheMenuItems() {
        var quit = false
        let footer = PopoverFooter(onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {}, onQuit: { quit = true }) {
            Toggle("Show Upcoming Days", isOn: .constant(true))
            Divider()
        }
        #expect(footer.menuItems != nil)
        footer.onQuit()
        #expect(quit)
    }

    @Test func labelledMenuItemsStillWork() {
        let footer = PopoverFooter(
            actions: [.init("Statistics…", symbol: "chart.bar.xaxis", perform: {})],
            onSettings: {},
            onCheckForUpdates: {},
            onBuyMeACoffee: {},
            menuItems: {
                Button("Export…") {}
            })
        #expect(footer.menuItems != nil)
        #expect(footer.actions.map(\.id) == ["Statistics…"])
    }

    @Test func noMenuItemsWithoutAClosure() {
        let plain = PopoverFooter(onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {})
        #expect(plain.menuItems == nil)
        var quit = false
        let quitting = PopoverFooter(actions: [], onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {},
                                     onQuit: { quit = true })
        #expect(quitting.menuItems == nil)
        quitting.onQuit()
        #expect(quit)
    }

    @Test func onlyTwoActionsAreShown() {
        let actions = (["a", "b", "c"] as [String]).map { PopoverFooter.Action($0, symbol: "circle", perform: {}) }
        let footer = PopoverFooter(actions: actions, onSettings: {}, onCheckForUpdates: {}, onBuyMeACoffee: {})
        #expect(footer.actions.map(\.id) == ["a", "b"])
    }
}
