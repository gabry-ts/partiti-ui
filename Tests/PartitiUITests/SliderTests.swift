import Testing
@testable import PartitiUI

@Suite struct SliderTests {
    @Test func withoutAStepTheValueIsOnlyClamped() {
        #expect(PUISlider.snapped(0.337, in: 0...1, step: nil) == 0.337)
        #expect(PUISlider.snapped(1.4, in: 0...1, step: nil) == 1)
        #expect(PUISlider.snapped(-3, in: 0...1, step: nil) == 0)
        #expect(PUISlider.snapped(0.337, in: 0...1, step: 0) == 0.337)
    }

    @Test func aStepSnapsFromTheStartOfTheRange() {
        #expect(PUISlider.snapped(42, in: 0...100, step: 5) == 40)
        #expect(PUISlider.snapped(43, in: 0...100, step: 5) == 45)
        #expect(PUISlider.snapped(12.2, in: 9...18, step: 0.5) == 12)
        #expect(PUISlider.snapped(13, in: 10...20, step: 4) == 14)
    }

    @Test func aSnappedValueStaysInRange() {
        #expect(PUISlider.snapped(250, in: 0...100, step: 5) == 100)
        #expect(PUISlider.snapped(-4, in: 0...100, step: 5) == 0)
        #expect(PUISlider.snapped(11, in: 0...10, step: 4) == 10)
    }
}
