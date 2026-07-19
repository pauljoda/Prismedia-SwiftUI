import XCTest

@testable import PrismediaCore

@MainActor
final class UserDefaultsLocalSessionStateCleanerTests: XCTestCase {
    func testClearRemovesAccountStateAndPreservesDevicePreferences() async throws {
        let suiteName = "UserDefaultsLocalSessionStateCleanerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let cacheRoot = FileManager.default.temporaryDirectory.appending(
            path: "UserDefaultsLocalSessionStateCleanerTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        try Data("cached book".utf8).write(to: cacheRoot.appending(path: "book.epub"))
        defer { try? FileManager.default.removeItem(at: cacheRoot) }

        let accountKeys = [
            "prismedia.music.playback-restoration.v1",
            "prismedia.music.playback-progress.v1",
            "prismedia.allowsNsfwContent.user-id",
            "prismedia.entity-grid.preferences.v1.movies",
            "prismedia.entity-grid.presets.v1.movies",
            "prismedia.reader.epub.bookmarks.v1.user.book",
            "prismedia.reader.epub.locator.v1.book",
        ]
        for key in accountKeys {
            defaults.set("private", forKey: key)
        }

        let devicePreferenceKeys = [
            "prismedia.lastServerURL",
            "prismedia.device-identifier",
            "prismedia.music.playback-preferences.v1",
            "prismedia.reader.epub.preferences.v1",
            "video.playback.engine",
        ]
        for key in devicePreferenceKeys {
            defaults.set("preference", forKey: key)
        }

        let urlCache = URLCache(memoryCapacity: 1_024, diskCapacity: 0)
        let request = URLRequest(url: URL(string: "https://media.example.test/private")!)
        let response = URLResponse(
            url: request.url!,
            mimeType: "application/json",
            expectedContentLength: 2,
            textEncodingName: nil
        )
        urlCache.storeCachedResponse(
            CachedURLResponse(response: response, data: Data("{}".utf8)),
            for: request
        )

        let cleaner = UserDefaultsLocalSessionStateCleaner(
            defaults: defaults,
            fileManager: .default,
            cacheDirectory: cacheRoot,
            urlCache: urlCache
        )

        await cleaner.clear()

        for key in accountKeys {
            XCTAssertNil(defaults.object(forKey: key), key)
        }
        for key in devicePreferenceKeys {
            XCTAssertEqual(defaults.string(forKey: key), "preference", key)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheRoot.path))
        XCTAssertNil(urlCache.cachedResponse(for: request))
    }
}
