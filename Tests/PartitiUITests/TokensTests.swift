import AppKit
import SwiftUI
import Testing
@testable import PartitiUI

@Suite struct AccentTests {
    @Test func hexValuesMatchTheSite() {
        let expected: [AppAccent: String] = [
            .tuuli: "#2F7BFF", .kaiku: "#E8364F", .kiito: "#22CBBB", .mittari: "#F59E0B", .kello: "#4C6EF5"
        ]
        for accent in AppAccent.allCases {
            #expect(accent.hex == expected[accent])
        }
    }

    @Test func colorMatchesRGB() throws {
        for accent in AppAccent.allCases {
            let c = try #require(NSColor(accent.color).usingColorSpace(.sRGB))
            #expect(Int((c.redComponent * 255).rounded()) == Int((accent.rgb >> 16) & 0xFF))
            #expect(Int((c.greenComponent * 255).rounded()) == Int((accent.rgb >> 8) & 0xFF))
            #expect(Int((c.blueComponent * 255).rounded()) == Int(accent.rgb & 0xFF))
        }
    }

    @Test func namesAndLabels() {
        #expect(AppAccent.mittari.name == "Mittari")
        #expect(AppAccent.allCases.filter(\.prefersDarkLabel) == [.kiito, .mittari])
    }
}

@Suite struct ScaleTests {
    @Test func spacingSitsOnTheGrid() {
        #expect(PUI.Space.scale.map(\.value) == [2, 4, 6, 8, 12, 16, 24])
        for step in PUI.Space.scale {
            #expect(step.value.truncatingRemainder(dividingBy: 2) == 0)
        }
    }

    @Test func typeScaleIsInOrder() {
        #expect(PUI.Font.scale.map(\.name) == [
            "display", "title", "stat", "paneTitle", "headline", "body", "callout", "label", "caption", "badge"
        ])
        #expect(PUI.Font.badgeTracking == 0.6)
    }

    @Test func controlHeights() {
        #expect([PUI.Control.small, PUI.Control.regular, PUI.Control.large] == [22, 28, 34])
    }
}

@Suite struct RadiusTests {
    @Test func popoverIsConcentricWithCards() {
        #expect(PUI.Radius.popover == PUI.Radius.card + PUI.Popover.margin)
        #expect(PUI.Radius.concentric(PUI.Radius.popover, inset: PUI.Popover.margin) == PUI.Radius.card)
    }

    @Test func concentricNeverGoesNegative() {
        #expect(PUI.Radius.concentric(20, inset: 8) == 12)
        #expect(PUI.Radius.concentric(6, inset: 12) == 0)
    }

    @Test func tileRoundsAt27Percent() {
        #expect(PUI.Radius.tile(22) == 6)
        #expect(PUI.Radius.tile(40) == 11)
        #expect(PUI.Radius.tile(96) == 26)
    }
}

@Suite struct BlendTests {
    private func components(_ color: Color) throws -> [Int] {
        let c = try #require(NSColor(color).usingColorSpace(.sRGB))
        return [c.redComponent, c.greenComponent, c.blueComponent].map { Int(($0 * 255).rounded()) }
    }

    @Test func blendEndpoints() throws {
        let red = Color(rgb: 0xFF0000)
        #expect(try components(PUI.blendSRGB(red, .black, 0)) == [255, 0, 0])
        #expect(try components(PUI.blendSRGB(red, .black, 1)) == [0, 0, 0])
        #expect(try components(PUI.blendSRGB(red, .black, 2)) == [0, 0, 0])
    }

    @Test func blendMidpoint() throws {
        let mid = PUI.blendSRGB(Color(rgb: 0x000000), Color(rgb: 0xFFFFFF), 0.5)
        #expect(try components(mid) == [128, 128, 128])
    }

    @Test func legibleOnlyDeepensInLight() throws {
        let accent = AppAccent.kello
        #expect(try components(accent.legible(.dark)) == components(accent.color))
        let light = try components(accent.legible(.light))
        let base = try components(accent.color)
        #expect(zip(light, base).allSatisfy { $0 < $1 })
    }
}

@Suite struct MenuBarFontTests {
    private func width(_ text: String, _ font: NSFont) -> CGFloat {
        NSAttributedString(string: text, attributes: [.font: font]).size().width
    }

    @Test func matchesTheSwiftUIMenuBarFont() {
        #expect(PUI.Font.menuBarNSFont().pointSize == PUI.Font.menuBarSize)
        #expect(PUI.Font.menuBarNSFont(size: 15).pointSize == 15)
        let traits = PUI.Font.menuBarNSFont().fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any]
        let weight = traits?[.weight] as? CGFloat
        #expect(weight.map { abs($0 - NSFont.Weight.medium.rawValue) < 0.01 } == true)
    }

    @Test func digitsAreMonospaced() {
        let font = PUI.Font.menuBarNSFont()
        #expect(width("1111", font) == width("8888", font))
    }
}
