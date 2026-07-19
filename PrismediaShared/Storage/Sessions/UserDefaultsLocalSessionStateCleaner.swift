import Foundation

@MainActor
public final class UserDefaultsLocalSessionStateCleaner: LocalSessionStateClearing {
    private static let exactKeys = [
        "prismedia.music.playback-restoration.v1",
        "prismedia.music.playback-progress.v1",
    ]

    private static let keyPrefixes = [
        "prismedia.allowsNsfwContent.",
        "prismedia.entity-grid.preferences.v1.",
        "prismedia.entity-grid.presets.v1.",
        "prismedia.reader.epub.bookmarks.v1.",
        "prismedia.reader.epub.locator.v1.",
    ]

    private let defaults: UserDefaults
    private let fileManager: FileManager
    private let cacheDirectory: URL?
    private let urlCache: URLCache

    public convenience init() {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.init(
            defaults: .standard,
            fileManager: .default,
            cacheDirectory: root?.appending(path: "Prismedia", directoryHint: .isDirectory),
            urlCache: .shared
        )
    }

    public init(
        defaults: UserDefaults,
        fileManager: FileManager,
        cacheDirectory: URL?,
        urlCache: URLCache
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory
        self.urlCache = urlCache
    }

    public func clear() async {
        for key in defaults.dictionaryRepresentation().keys
        where Self.exactKeys.contains(key)
            || Self.keyPrefixes.contains(where: key.hasPrefix)
        {
            defaults.removeObject(forKey: key)
        }

        urlCache.removeAllCachedResponses()
        if let cacheDirectory {
            try? fileManager.removeItem(at: cacheDirectory)
        }
    }
}
