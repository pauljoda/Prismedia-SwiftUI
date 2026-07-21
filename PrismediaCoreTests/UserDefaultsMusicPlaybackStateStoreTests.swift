import XCTest

@testable import PrismediaCore

@MainActor
final class UserDefaultsMusicPlaybackStateStoreTests: XCTestCase {
    func testSavingANewQueueReplacesThePreviousRestoration() {
        let suiteName = "UserDefaultsMusicPlaybackStateStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsMusicPlaybackStateStore(defaults: defaults)
        let originalTrack = MusicTrack(id: UUID(), title: "Original Track")
        let replacementTrack = MusicTrack(id: UUID(), title: "Replacement Track")

        store.save(
            MusicPlaybackRestoration(
                queue: MusicQueue(tracks: [originalTrack]),
                elapsedTime: 12
            )
        )
        store.save(
            MusicPlaybackRestoration(
                queue: MusicQueue(tracks: [replacementTrack]),
                elapsedTime: 0
            )
        )

        XCTAssertEqual(store.load()?.tracks, [replacementTrack])
        XCTAssertEqual(store.load()?.currentTrackID, replacementTrack.id)
        XCTAssertEqual(store.load()?.elapsedTime, 0)
    }

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

    func testProgressCheckpointUpdatesResumeStateWithoutReencodingTheQueue() {
        let suiteName = "UserDefaultsMusicPlaybackStateStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsMusicPlaybackStateStore(defaults: defaults)
        let tracks = (0..<1_000).map { index in
            MusicTrack(id: UUID(), title: "Track \(index)")
        }
        let restoration = MusicPlaybackRestoration(
            queue: MusicQueue(tracks: tracks),
            elapsedTime: 0
        )
        store.save(restoration)
        let stateKey = "prismedia.music.playback-restoration.v1"
        let encodedQueue = defaults.data(forKey: stateKey)!

        store.saveProgress(
            MusicPlaybackProgressCheckpoint(
                currentTrackID: tracks[0].id,
                elapsedTime: 42,
                audiobookCompleted: false
            )
        )

        let progressData = defaults.data(forKey: "prismedia.music.playback-progress.v1")!
        XCTAssertGreaterThan(encodedQueue.count, 100_000)
        XCTAssertLessThan(progressData.count, 256)
        XCTAssertEqual(defaults.data(forKey: stateKey), encodedQueue)
        XCTAssertEqual(store.load()?.elapsedTime, 42)
        XCTAssertEqual(store.load()?.currentTrackID, tracks[0].id)
    }
}
