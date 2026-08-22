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
        let replacementTrack = MusicTrack(
            id: UUID(),
            title: "Replacement Track",
            artist: "Artist",
            artistID: UUID(),
            album: "Album",
            albumID: UUID()
        )

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

    func testLegacyPersistedTrackWithoutWantedFlagRemainsPlayable() throws {
        let trackID = UUID()
        let data = Data(#"{"id":"\#(trackID)","title":"Legacy Track","sortOrder":0}"#.utf8)

        let track = try JSONDecoder().decode(MusicTrack.self, from: data)

        XCTAssertFalse(track.isWanted)
        XCTAssertTrue(track.isPlayable)
    }

    func testLegacyPlaybackContextDefaultsCapabilityPoliciesToDisabled() throws {
        let ownerID = UUID()
        let data = Data(
            #"{"playbackOwnerEntityID":"\#(ownerID)","playbackOwnerTitle":"Legacy Book","playbackOwnerEntityKind":"book"}"#
                .utf8
        )

        let context = try JSONDecoder().decode(MusicPlaybackContext.self, from: data)

        XCTAssertEqual(context.playbackOwnerEntityID, ownerID)
        XCTAssertFalse(context.preservesQueueOrder)
        XCTAssertFalse(context.supportsPlaybackRate)
    }

    func testLegacyBookProgressContextDecodesIntoGenericMappedProgress() throws {
        let ownerID = UUID()
        let trackID = UUID()
        let data = Data(
            #"{"playbackOwnerEntityID":"\#(ownerID)","bookProgressMappings":[{"trackId":"\#(trackID)","currentEntityId":"\#(ownerID)","unit":"cfi","startIndex":20,"endIndex":40,"total":100,"mode":"paged","readerLocation":"Text/chapter.xhtml"}]}"#
                .utf8
        )

        let context = try JSONDecoder().decode(MusicPlaybackContext.self, from: data)

        XCTAssertTrue(context.usesMappedProgress)
        let mapping = try XCTUnwrap(context.progressMappings?.first)
        XCTAssertEqual(mapping.itemID, trackID)
        XCTAssertEqual(mapping.resourceLocation, "Text/chapter.xhtml")
        let encoded = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(context)) as? [String: Any]
        )
        XCTAssertNotNil(encoded["progressMappings"])
        XCTAssertNil(encoded["bookProgressMappings"])
    }

    func testLegacyAudiobookCompletionCheckpointDecodesIntoMappedProgressState() throws {
        let trackID = UUID()
        let data = Data(
            #"{"currentTrackID":"\#(trackID)","elapsedTime":42,"audiobookCompleted":true}"#.utf8
        )

        let checkpoint = try JSONDecoder().decode(MusicPlaybackProgressCheckpoint.self, from: data)

        XCTAssertEqual(checkpoint.currentTrackID, trackID)
        XCTAssertTrue(checkpoint.mappedProgressCompleted == true)
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
                mappedProgressCompleted: false
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
