import Foundation
import Testing
@testable import PartitiUI

@Suite struct ResourceBundleTests {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func missingBundleFallsBackToNil() throws {
        let empty = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: empty) }
        #expect(PUIResources.locate(PUIResources.bundleName, in: []) == nil)
        #expect(PUIResources.locate(PUIResources.bundleName, in: [empty]) == nil)
    }

    @Test func aFileNamedLikeTheBundleIsSkipped() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try Data().write(to: dir.appendingPathComponent(PUIResources.bundleName))
        #expect(PUIResources.locate(PUIResources.bundleName, in: [dir]) == nil)
    }

    @Test func firstDirectoryHoldingTheBundleWins() throws {
        let missing = try temporaryDirectory()
        let first = try temporaryDirectory()
        let second = try temporaryDirectory()
        defer { [missing, first, second].forEach { try? FileManager.default.removeItem(at: $0) } }
        for dir in [first, second] {
            try FileManager.default.createDirectory(at: dir.appendingPathComponent(PUIResources.bundleName), withIntermediateDirectories: true)
        }
        let bundle = try #require(PUIResources.locate(PUIResources.bundleName, in: [missing, first, second]))
        #expect(bundle.bundleURL.standardizedFileURL.deletingLastPathComponent().path == first.standardizedFileURL.path)
    }

    @Test func theBuiltBundleIsFound() {
        #expect(PUIResources.bundle != nil)
    }
}

@Suite struct StringCatalogTests {
    private static let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/PartitiUI")

    private func catalog() throws -> [String: Any] {
        let data = try Data(contentsOf: Self.sources.appendingPathComponent("Resources/Localizable.xcstrings"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["sourceLanguage"] as? String == "en")
        return try #require(json["strings"] as? [String: Any])
    }

    /// The keys of every `Text(pui:)` in the sources, with interpolations as `%@`.
    private func keysInSources() throws -> Set<String> {
        let files = try FileManager.default.contentsOfDirectory(at: Self.sources, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        let call = try Regex(#"Text\(pui: "((?:[^"\\]|\\.)*)"\)"#)
        let interpolation = try Regex(#"\\\([^)]*\)"#)
        var keys = Set<String>()
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            for match in source.matches(of: call) {
                guard let key = match.output[1].substring else { continue }
                keys.insert(String(key).replacing(interpolation, with: "%@"))
            }
        }
        return keys
    }

    @Test func everyBuiltInStringIsInTheCatalog() throws {
        let keys = try keysInSources()
        #expect(!keys.isEmpty)
        let strings = try catalog()
        for key in keys {
            #expect(strings[key] != nil, "\(key) is missing from Localizable.xcstrings")
        }
    }

    @Test func everyStringIsTranslatedToItalian() throws {
        for (key, entry) in try catalog() {
            let entry = try #require(entry as? [String: Any])
            let localizations = entry["localizations"] as? [String: Any]
            let unit = (localizations?["it"] as? [String: Any])?["stringUnit"] as? [String: Any]
            #expect(unit?["state"] as? String == "translated", "\(key) has no Italian translation")
            let value = unit?["value"] as? String ?? ""
            #expect(!value.isEmpty)
            #expect(key.contains("%@") == value.contains("%@"), "\(key) and its translation disagree on arguments")
        }
    }
}
