import Testing
@testable import PartitiUI

@Suite struct ReorderTests {
    private struct Entry: Identifiable, Equatable {
        let id: String
        var isOn = true
    }

    private func entries(_ ids: String) -> [Entry] { ids.map { Entry(id: String($0)) } }
    private func ids(_ entries: [Entry]) -> String { entries.map(\.id).joined() }

    @Test func draggedDownLandsAfterTheTarget() {
        #expect(Reorder.moving(Array("abcd"), from: 0, to: 2) == Array("bcad"))
        #expect(Reorder.moving(Array("abcd"), from: 0, to: 3) == Array("bcda"))
    }

    @Test func draggedUpLandsBeforeTheTarget() {
        #expect(Reorder.moving(Array("abcd"), from: 3, to: 1) == Array("adbc"))
        #expect(Reorder.moving(Array("abcd"), from: 3, to: 0) == Array("dabc"))
    }

    @Test func neighboursSwap() {
        #expect(Reorder.moving(Array("abcd"), from: 1, to: 2) == Array("acbd"))
        #expect(Reorder.moving(Array("abcd"), from: 2, to: 1) == Array("acbd"))
    }

    @Test func aMoveOntoItselfOrOutOfRangeChangesNothing() {
        #expect(Reorder.moving(Array("abcd"), from: 2, to: 2) == Array("abcd"))
        #expect(Reorder.moving(Array("abcd"), from: 4, to: 0) == Array("abcd"))
        #expect(Reorder.moving(Array("abcd"), from: 0, to: -1) == Array("abcd"))
        #expect(Reorder.moving([Character](), from: 0, to: 0).isEmpty)
    }

    @Test func lockedItemsKeepTheirPlace() {
        let locked: (Character) -> Bool = { $0.isUppercase }
        #expect(Reorder.moving(Array("AbcDe"), from: 1, to: 4, isLocked: locked) == Array("AceDb"))
        #expect(Reorder.moving(Array("AbcDe"), from: 4, to: 1, isLocked: locked) == Array("AebDc"))
    }

    @Test func lockedItemsDontMoveAndArentTargets() {
        let locked: (Character) -> Bool = { $0.isUppercase }
        #expect(Reorder.moving(Array("AbcDe"), from: 0, to: 2, isLocked: locked) == Array("AbcDe"))
        #expect(Reorder.moving(Array("AbcDe"), from: 2, to: 3, isLocked: locked) == Array("AbcDe"))
    }

    @Test func movingByID() {
        #expect(ids(Reorder.moving(entries("abcd"), id: "a", onto: "c")) == "bcad")
        #expect(ids(Reorder.moving(entries("abcd"), id: "d", onto: "b")) == "adbc")
        #expect(ids(Reorder.moving(entries("abcd"), id: "x", onto: "b")) == "abcd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "a", onto: "x")) == "abcd")
    }

    @Test func movingByOffsetSkipsLockedItemsAndStopsAtTheEnds() {
        let locked: (Entry) -> Bool = { $0.id == "a" || $0.id == "c" }
        #expect(ids(Reorder.moving(entries("abcd"), id: "b", by: 1)) == "acbd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "b", by: -1)) == "bacd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "a", by: -1)) == "abcd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "d", by: 1)) == "abcd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "a", by: 9)) == "bcda")
        #expect(ids(Reorder.moving(entries("abcd"), id: "d", by: -1, isLocked: locked)) == "adcb")
        #expect(ids(Reorder.moving(entries("abcd"), id: "b", by: -1, isLocked: locked)) == "abcd")
        #expect(ids(Reorder.moving(entries("abcd"), id: "a", by: 1, isLocked: locked)) == "abcd")
    }

    @Test func normalizingDropsUnknownAndAppendsNew() {
        #expect(Reorder.normalized(["c", "x", "a"], known: ["a", "b", "c", "d"]) == ["c", "a", "b", "d"])
        #expect(Reorder.normalized([String](), known: ["a", "b"]) == ["a", "b"])
        #expect(Reorder.normalized(["a", "b"], known: []) == [])
    }

    @Test func normalizingDropsDuplicates() {
        #expect(Reorder.normalized(["b", "a", "b", "a"], known: ["a", "b", "c", "c"]) == ["b", "a", "c"])
    }

    @Test func normalizingKeepsTheSavedState() {
        let saved = [Entry(id: "b", isOn: false), Entry(id: "gone", isOn: false)]
        let result = Reorder.normalized(saved, known: entries("abc"), by: \.id)
        #expect(result == [Entry(id: "b", isOn: false), Entry(id: "a"), Entry(id: "c")])
    }
}
