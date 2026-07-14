import XCTest

@testable import PrismediaCore

@MainActor
final class UserDefaultsMusicPlaybackStateStoreTests: XCTestCase {
    func testClearingQueueRestorationKeepsGlobalPlaybackPreferences() {
        let suiteName = "UserDefaultsMusicPlaybackStateStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsMusicPlaybackStateStore(defaults: defaults)
        let preferences = MusicPlaybackPreferences(repeatMode: .all, isShuffled: true)
        let track = MusicTrack(id: UUID(), title: "Track")

        store.savePreferences(preferences)
        store.save(
            MusicPlaybackRestoration(
                queue: MusicQueue(tracks: [track]),
                elapsedTime: 12
            )
        )

        store.clear()

        XCTAssertNil(store.load())
        XCTAssertEqual(store.loadPreferences(), preferences)
    }
}
