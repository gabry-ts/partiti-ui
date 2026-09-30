import Foundation
import SwiftUI

/// Where Partiti UI's own strings come from.
///
/// The package's resource bundle is looked up by hand rather than through SwiftPM's
/// generated `Bundle.module`, which stops the app when the bundle isn't where it expects.
/// If the bundle can't be found, the built-in strings fall back to their English keys.
enum PUIResources {
    /// The resource bundle SwiftPM builds for this target.
    static let bundleName = "PartitiUI_PartitiUI.bundle"

    /// The resource bundle, or nil when the app doesn't ship it.
    static let bundle: Bundle? = locate(bundleName, in: searchDirectories)

    /// Where the bundle can be: Contents/Resources of an assembled or Xcode-built app,
    /// next to the executable for `swift run`, next to the test bundle for `swift test`.
    static var searchDirectories: [URL] {
        let code = Bundle(for: BundleToken.self)
        return [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
            Bundle.main.executableURL?.deletingLastPathComponent(),
            code.resourceURL,
            code.bundleURL.deletingLastPathComponent()
        ].compactMap { $0 }
    }

    /// The first directory in `directories` holding a bundle called `name`, opened.
    static func locate(_ name: String, in directories: [URL]) -> Bundle? {
        for directory in directories {
            let url = directory.appendingPathComponent(name, isDirectory: true)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  let bundle = Bundle(url: url) else { continue }
            return bundle
        }
        return nil
    }

    private final class BundleToken {}
}

extension Text {
    /// One of Partiti UI's own strings, translated from the package's string catalog in the
    /// environment's locale. Without the resource bundle, the English key is shown.
    init(pui key: LocalizedStringKey) {
        self.init(key, bundle: PUIResources.bundle)
    }
}
