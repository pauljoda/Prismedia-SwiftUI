import XCTest

@testable import PrismediaCore

@MainActor
final class MusicPlayerControllerTests: XCTestCase {
    func testStartingQueueLoadsAuthenticatedStreamAndPlays() {
        let track = makeTrack(idSuffix: 1)
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)

        controller.play(tracks: [track], startingAt: track.id)

        XCTAssertEqual(engine.loadedURLs, [service.audioStreamURL(for: track.id)!])
        XCTAssertEqual(engine.playCallCount, 1)
        XCTAssertTrue(controller.isPlaying)
        XCTAssertEqual(controller.currentTrack, track)
    }

    func testPreparingShuffledQueueDefersPlaybackUntilResume() {
        let tracks = (1...12).map { makeTrack(idSuffix: $0) }
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)

        controller.preparePlayback(tracks: tracks, queueMode: .shuffled)

        XCTAssertTrue(controller.queue.isShuffled)
        let preparedTrack = controller.currentTrack
        XCTAssertNotNil(preparedTrack)
        XCTAssertTrue(engine.loadedURLs.isEmpty)
        XCTAssertEqual(engine.playCallCount, 0)
        XCTAssertFalse(controller.isPlaying)

        controller.resume()

        XCTAssertEqual(engine.loadedURLs, [service.audioStreamURL(for: preparedTrack!.id)!])
        XCTAssertEqual(engine.playCallCount, 1)
        XCTAssertTrue(controller.isPlaying)
    }

    func testIncrementalQueueExpansionCannotAppendToAReplacementQueue() {
        let initialTracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let replacementTracks = [makeTrack(idSuffix: 3), makeTrack(idSuffix: 4)]
        let lateTrack = makeTrack(idSuffix: 5)
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub()
        )

        let initialQueueID = controller.preparePlayback(tracks: initialTracks, queueMode: .shuffled)
        let replacementQueueID = controller.preparePlayback(tracks: replacementTracks)

        XCTAssertFalse(controller.appendUpcomingTracks([lateTrack], to: initialQueueID))
        XCTAssertEqual(controller.queue.tracks, replacementTracks)

        XCTAssertTrue(controller.appendUpcomingTracks([lateTrack], to: replacementQueueID))
        XCTAssertEqual(controller.queue.tracks, replacementTracks + [lateTrack])
    }

    func testPlaybackRateAppliesImmediatelyAndSurvivesTrackChanges() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let engine = AudioPlaybackEngineSpy()
        let controller = MusicPlayerController(
            engine: engine,
            service: MusicPlaybackServiceStub()
        )

        controller.setPlaybackRate(1.5)
        controller.play(
            tracks: tracks,
            context: MusicPlaybackContext(
                playbackOwnerEntityID: UUID(),
                playbackOwnerTitle: "Book",
                playbackOwnerEntityKind: .book
            )
        )
        controller.skipToNext()

        XCTAssertEqual(controller.playbackRate, 1.5)
        XCTAssertEqual(engine.playbackRates, [1.5, 1.5, 1.5])
    }

    func testStartingOrdinaryMusicResetsAudiobookPlaybackRate() {
        let track = makeTrack(idSuffix: 1)
        let engine = AudioPlaybackEngineSpy()
        let controller = MusicPlayerController(
            engine: engine,
            service: MusicPlaybackServiceStub()
        )

        controller.setPlaybackRate(1.75)
        controller.play(tracks: [track])

        XCTAssertEqual(controller.playbackRate, 1)
        XCTAssertEqual(engine.playbackRates.suffix(2), [1, 1])
    }

    func testSelectingAndReorderingUpNextTracksUpdatesPlaybackAndQueueOrder() {
        let tracks = [
            makeTrack(idSuffix: 1),
            makeTrack(idSuffix: 2),
            makeTrack(idSuffix: 3),
            makeTrack(idSuffix: 4),
        ]
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)
        controller.play(tracks: tracks)

        controller.moveUpcomingTrack(id: tracks[3].id, before: tracks[1].id)
        XCTAssertEqual(
            controller.queue.upNextTracks.map(\.id),
            [tracks[3].id, tracks[1].id, tracks[2].id]
        )

        controller.skipToUpcomingTrack(id: tracks[2].id)

        XCTAssertEqual(controller.currentTrack?.id, tracks[2].id)
        XCTAssertEqual(controller.queue.history.map(\.track.id), [tracks[0].id])
        XCTAssertEqual(engine.loadedURLs.last, service.audioStreamURL(for: tracks[2].id))
    }

    func testNaturalCompletionRecordsPlayAndAdvances() async {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)
        controller.play(tracks: tracks)

        await controller.handlePlaybackEnded()

        XCTAssertEqual(service.recordedTrackIDs, [tracks[0].id])
        XCTAssertEqual(controller.currentTrack, tracks[1])
        XCTAssertTrue(controller.isPlaying)
    }

    func testQuickNextRecordsSkippedPlaybackEventForPreviousTrack() async {
        let tracks = [
            makeTrack(idSuffix: 1, duration: 180),
            makeTrack(idSuffix: 2, duration: 240),
        ]
        let service = MusicPlaybackServiceStub()
        let clock = TestMusicPlaybackClock()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: service,
            playbackClock: clock
        )
        controller.play(tracks: tracks)
        controller.updateElapsedTime(4)

        controller.skipToNext()
        await controller.flushPendingPlaybackReports()

        XCTAssertEqual(service.skippedTrackIDs, [tracks[0].id])
        XCTAssertEqual(service.skippedPositions, [4])
        XCTAssertEqual(service.skippedDurations, [180])
    }

    func testQueueJumpUsesQuickSkipWindowAndAudiobooksStayExcluded() async {
        let tracks = [
            makeTrack(idSuffix: 1, duration: 180),
            makeTrack(idSuffix: 2, duration: 240),
            makeTrack(idSuffix: 3, duration: 300),
        ]
        let service = MusicPlaybackServiceStub()
        let clock = TestMusicPlaybackClock()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: service,
            playbackClock: clock
        )
        controller.play(tracks: tracks)
        clock.advance(by: 11)

        controller.skipToUpcomingTrack(id: tracks[2].id)
        await controller.flushPendingPlaybackReports()

        XCTAssertTrue(service.skippedTrackIDs.isEmpty)

        controller.play(
            tracks: tracks,
            context: MusicPlaybackContext(
                playbackOwnerEntityID: UUID(),
                playbackOwnerTitle: "Book",
                playbackOwnerEntityKind: .book
            )
        )
        controller.skipToUpcomingTrack(id: tracks[2].id)
        await controller.flushPendingPlaybackReports()

        XCTAssertTrue(service.skippedTrackIDs.isEmpty)
    }

    func testCompletionAtQueueEndStopsWithoutReloading() async {
        let track = makeTrack(idSuffix: 1)
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)
        controller.play(tracks: [track])

        await controller.handlePlaybackEnded()

        XCTAssertEqual(service.recordedTrackIDs, [track.id])
        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(engine.loadedURLs.count, 1)
    }

    func testSlowCompletionReportCannotAdvanceAReplacementQueue() async {
        let completedTrack = makeTrack(idSuffix: 1)
        let replacementTracks = [makeTrack(idSuffix: 2), makeTrack(idSuffix: 3)]
        let engine = AudioPlaybackEngineSpy()
        let service = SuspendingMusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)
        controller.play(tracks: [completedTrack])

        let completion = Task { await controller.handlePlaybackEnded() }
        await Task.yield()
        controller.play(tracks: replacementTracks)
        service.finishRecording()
        await completion.value

        XCTAssertEqual(controller.currentTrack, replacementTracks[0])
    }

    func testMissingStreamURLSurfacesFailureWithoutPlaying() {
        let track = makeTrack(idSuffix: 1)
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub(missingStreamIDs: [track.id])
        let controller = MusicPlayerController(engine: engine, service: service)

        controller.play(tracks: [track])

        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(controller.errorMessage, "This track does not have a playable stream.")
        XCTAssertTrue(engine.loadedURLs.isEmpty)
        XCTAssertEqual(engine.playCallCount, 0)
    }

    func testDirectWantedTrackPlayDoesNotCreateAQueueOrRequestAStream() {
        let wanted = makeTrack(idSuffix: 1, isWanted: true)
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)

        controller.play(tracks: [wanted], startingAt: wanted.id)

        XCTAssertTrue(controller.queue.tracks.isEmpty)
        XCTAssertNil(controller.currentTrack)
        XCTAssertFalse(controller.isPlaying)
        XCTAssertTrue(service.requestedStreamIDs.isEmpty)
        XCTAssertTrue(engine.loadedURLs.isEmpty)
        XCTAssertEqual(engine.playCallCount, 0)
    }

    func testDirectWantedTrackPlayDoesNotInterruptExistingPlayback() {
        let playable = makeTrack(idSuffix: 1)
        let wanted = makeTrack(idSuffix: 2, isWanted: true)
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(engine: engine, service: service)
        controller.play(tracks: [playable])

        controller.play(tracks: [wanted], startingAt: wanted.id)

        XCTAssertEqual(controller.queue.tracks, [playable])
        XCTAssertEqual(controller.currentTrack, playable)
        XCTAssertTrue(controller.isPlaying)
        XCTAssertEqual(service.requestedStreamIDs, [playable.id])
        XCTAssertEqual(engine.playCallCount, 1)
        XCTAssertEqual(engine.pauseCallCount, 0)
    }

    func testClearPlaybackStopsEngineAndRemovesQueueAndRestoration() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let engine = AudioPlaybackEngineSpy()
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: engine,
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )
        controller.play(tracks: tracks)
        var publicationCount = 0
        controller.onNowPlayingStateChanged = { publicationCount += 1 }

        controller.clearPlayback()

        XCTAssertEqual(engine.pauseCallCount, 1)
        XCTAssertFalse(controller.isPlaying)
        XCTAssertNil(controller.currentTrack)
        XCTAssertTrue(controller.queue.tracks.isEmpty)
        XCTAssertNil(controller.context)
        XCTAssertEqual(controller.elapsedTime, 0)
        XCTAssertNil(controller.errorMessage)
        XCTAssertEqual(store.clearCallCount, 1)
        XCTAssertEqual(publicationCount, 1)
    }

    func testDiscardingSessionPlaybackStopsAndRemovesRestorationWithoutReportingProgress() async {
        let track = makeTrack(idSuffix: 1)
        let service = MusicPlaybackServiceStub()
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: service,
            stateStore: store
        )
        controller.play(
            tracks: [track],
            context: MusicPlaybackContext(
                playbackOwnerEntityID: UUID(),
                playbackOwnerTitle: "Private Audiobook",
                playbackOwnerEntityKind: .book
            )
        )

        controller.discardPlaybackState()
        await controller.flushPendingPlaybackReports()

        XCTAssertNil(controller.currentTrack)
        XCTAssertTrue(controller.queue.tracks.isEmpty)
        XCTAssertEqual(store.clearCallCount, 1)
        XCTAssertTrue(service.playbackUpdates.isEmpty)
    }

    func testRestoresQueueAndElapsedPositionWithoutAutoplaying() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let restoration = MusicPlaybackRestoration(
            tracks: tracks,
            orderedTrackIDs: [tracks[1].id, tracks[0].id],
            currentTrackID: tracks[1].id,
            repeatMode: .one,
            isShuffled: true,
            elapsedTime: 37.5
        )
        let engine = AudioPlaybackEngineSpy()
        let store = MusicPlaybackStateStoreSpy(restoration: restoration)
        let controller = MusicPlayerController(
            engine: engine,
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.restoreIfNeeded()

        XCTAssertEqual(controller.currentTrack?.id, tracks[1].id)
        XCTAssertEqual(controller.queue.orderedTracks.map(\.id), [tracks[1].id, tracks[0].id])
        XCTAssertEqual(controller.queue.repeatMode, .one)
        XCTAssertTrue(controller.queue.isShuffled)
        XCTAssertEqual(engine.seekPositions, [37.5])
        XCTAssertEqual(engine.playCallCount, 0)
        XCTAssertFalse(controller.isPlaying)
    }

    func testRestorationFiltersWantedCurrentTrackAndResetsElapsedPosition() {
        let wanted = makeTrack(idSuffix: 1, isWanted: true)
        let playable = makeTrack(idSuffix: 2)
        let restoration = MusicPlaybackRestoration(
            tracks: [wanted, playable],
            orderedTrackIDs: [wanted.id, playable.id],
            currentTrackID: wanted.id,
            repeatMode: .off,
            isShuffled: false,
            elapsedTime: 37.5,
            history: [MusicQueueHistoryEntry(sequence: 0, track: wanted)]
        )
        let engine = AudioPlaybackEngineSpy()
        let service = MusicPlaybackServiceStub()
        let controller = MusicPlayerController(
            engine: engine,
            service: service,
            stateStore: MusicPlaybackStateStoreSpy(restoration: restoration)
        )

        controller.restoreIfNeeded()

        XCTAssertEqual(controller.queue.tracks, [playable])
        XCTAssertEqual(controller.currentTrack, playable)
        XCTAssertTrue(controller.queue.history.isEmpty)
        XCTAssertEqual(controller.elapsedTime, 0)
        XCTAssertEqual(service.requestedStreamIDs, [playable.id])
        XCTAssertFalse(service.requestedStreamIDs.contains(wanted.id))
        XCTAssertTrue(engine.seekPositions.isEmpty)
        XCTAssertEqual(engine.playCallCount, 0)
    }

    func testRemoteResumeWaitsForPlaybackServiceAfterColdRestoration() {
        let track = makeTrack(idSuffix: 1)
        let restoration = MusicPlaybackRestoration(
            tracks: [track],
            orderedTrackIDs: [track.id],
            currentTrackID: track.id,
            repeatMode: .off,
            isShuffled: false,
            elapsedTime: 37.5
        )
        let engine = AudioPlaybackEngineSpy()
        let relay = MusicPlaybackServiceRelay()
        let controller = MusicPlayerController(
            engine: engine,
            service: relay,
            stateStore: MusicPlaybackStateStoreSpy(restoration: restoration)
        )

        controller.restoreIfNeeded()
        controller.resume()

        XCTAssertEqual(controller.currentTrack, track)
        XCTAssertTrue(engine.loadedURLs.isEmpty)
        XCTAssertEqual(engine.playCallCount, 0)

        let service = MusicPlaybackServiceStub()
        relay.connect(to: service)
        controller.playbackServiceDidConnect()

        XCTAssertEqual(engine.loadedURLs, [service.audioStreamURL(for: track.id)!])
        XCTAssertEqual(engine.seekPositions, [37.5])
        XCTAssertEqual(engine.playCallCount, 1)
        XCTAssertTrue(controller.isPlaying)
    }

    func testPlaybackServiceDisconnectPausesAndPreservesQueueRestoration() {
        let track = makeTrack(idSuffix: 1)
        let engine = AudioPlaybackEngineSpy()
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: engine,
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )
        controller.play(tracks: [track])

        controller.playbackServiceDidDisconnect()

        XCTAssertEqual(controller.currentTrack, track)
        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(engine.pauseCallCount, 1)
        XCTAssertEqual(store.clearCallCount, 0)

        controller.playbackServiceDidConnect()

        XCTAssertEqual(engine.loadedURLs.count, 2)
        XCTAssertEqual(engine.playCallCount, 1)
        XCTAssertFalse(controller.isPlaying)
    }

    func testPersistsQueueModesAndProgressInBoundedIntervals() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(tracks: tracks)
        controller.setRepeatMode(.all)
        controller.updateElapsedTime(2)
        controller.updateElapsedTime(6)
        controller.seek(to: 18)
        controller.pause()

        XCTAssertEqual(store.saved.last?.currentTrackID, tracks[0].id)
        XCTAssertEqual(store.saved.last?.repeatMode, .all)
        XCTAssertEqual(store.savedProgress.last?.currentTrackID, tracks[0].id)
        XCTAssertEqual(store.savedProgress.last?.elapsedTime, 18)
        XCTAssertLessThanOrEqual(store.saved.count, 6)
    }

    func testElapsedTimeCheckpointsDoNotRewriteTheQueueRestoration() {
        let tracks = (1...1_000).map { makeTrack(idSuffix: $0) }
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(tracks: tracks)
        XCTAssertEqual(store.saved.count, 1)

        controller.updateElapsedTime(6)
        controller.seek(to: 18)
        controller.pause()

        XCTAssertEqual(store.saved.count, 1)
        XCTAssertEqual(store.savedProgress.last?.currentTrackID, tracks[0].id)
        XCTAssertEqual(store.savedProgress.last?.elapsedTime, 18)
    }

    func testTrackTapUsesPersistedGlobalShuffleAndRepeatModes() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2), makeTrack(idSuffix: 3)]
        let store = MusicPlaybackStateStoreSpy(
            preferences: MusicPlaybackPreferences(repeatMode: .all, isShuffled: true)
        )
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(tracks: tracks, startingAt: tracks[1].id)

        XCTAssertEqual(controller.currentTrack?.id, tracks[1].id)
        XCTAssertEqual(controller.queue.repeatMode, .all)
        XCTAssertTrue(controller.queue.isShuffled)
        XCTAssertEqual(controller.queue.orderedTracks.first?.id, tracks[1].id)
    }

    func testQueuingMusicAfterRepeatOnePersistsRepeatAll() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let store = MusicPlaybackStateStoreSpy(
            preferences: MusicPlaybackPreferences(repeatMode: .one, isShuffled: false)
        )
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(tracks: tracks)

        XCTAssertEqual(controller.queue.repeatMode, .all)
        XCTAssertEqual(store.savedPreferences.last?.repeatMode, .all)
    }

    func testSkippingFromRepeatOnePersistsRepeatAll() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )
        controller.play(tracks: tracks, startingAt: tracks[1].id)
        controller.setRepeatMode(.one)

        controller.skipToNext()

        XCTAssertEqual(controller.currentTrack?.id, tracks[0].id)
        XCTAssertEqual(controller.queue.repeatMode, .all)
        XCTAssertEqual(store.savedPreferences.last?.repeatMode, .all)
    }

    func testPlayAllTurnsOffShuffleAndMakesOrderedPlaybackTheGlobalPreference() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2), makeTrack(idSuffix: 3)]
        let store = MusicPlaybackStateStoreSpy(
            preferences: MusicPlaybackPreferences(repeatMode: .off, isShuffled: true)
        )
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(tracks: tracks, queueMode: .ordered)

        XCTAssertFalse(controller.queue.isShuffled)
        XCTAssertEqual(controller.queue.orderedTracks.map(\.id), tracks.map(\.id))
        XCTAssertEqual(store.savedPreferences.last?.isShuffled, false)

        controller.play(tracks: tracks, startingAt: tracks[1].id)

        XCTAssertFalse(controller.queue.isShuffled)
        XCTAssertEqual(controller.currentTrack?.id, tracks[1].id)
    }

    func testModeChangesRemainAvailableAfterClearingTheQueue() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2), makeTrack(idSuffix: 3)]
        let store = MusicPlaybackStateStoreSpy()
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )
        controller.play(tracks: tracks)
        controller.setRepeatMode(.all)
        controller.setShuffleEnabled(true)

        controller.clearPlayback()
        controller.play(tracks: tracks, startingAt: tracks[2].id)

        XCTAssertEqual(controller.queue.repeatMode, .all)
        XCTAssertTrue(controller.queue.isShuffled)
        XCTAssertEqual(controller.currentTrack?.id, tracks[2].id)
    }

    func testReplacingAQueueCarriesThePreviousCurrentTrackIntoHistory() {
        let firstQueue = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2)]
        let secondQueue = [makeTrack(idSuffix: 3), makeTrack(idSuffix: 4)]
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub()
        )
        controller.play(tracks: firstQueue)

        controller.play(tracks: secondQueue)

        XCTAssertEqual(controller.queue.history.map(\.track.id), [firstQueue[0].id])
        XCTAssertEqual(controller.currentTrack?.id, secondQueue[0].id)

        controller.clearHistory()

        XCTAssertTrue(controller.queue.history.isEmpty)
        XCTAssertEqual(controller.currentTrack?.id, secondQueue[0].id)
    }

    func testOrderedAudiobookPlaybackDoesNotOverwriteTheGlobalShufflePreference() {
        let tracks = [makeTrack(idSuffix: 1), makeTrack(idSuffix: 2), makeTrack(idSuffix: 3)]
        let store = MusicPlaybackStateStoreSpy(
            preferences: MusicPlaybackPreferences(repeatMode: .off, isShuffled: true)
        )
        let controller = MusicPlayerController(
            engine: AudioPlaybackEngineSpy(),
            service: MusicPlaybackServiceStub(),
            stateStore: store
        )

        controller.play(
            tracks: tracks,
            context: MusicPlaybackContext(
                playbackOwnerEntityID: UUID(),
                playbackOwnerTitle: "Book",
                playbackOwnerEntityKind: .book
            )
        )
        XCTAssertFalse(controller.queue.isShuffled)

        controller.play(tracks: tracks)

        XCTAssertTrue(controller.queue.isShuffled)
    }

    private func makeTrack(
        idSuffix: Int,
        duration: Double? = nil,
        isWanted: Bool = false
    ) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSuffix))!,
            title: "Track \(idSuffix)",
            artist: "Artist",
            album: "Album",
            duration: duration,
            sortOrder: idSuffix - 1,
            isWanted: isWanted
        )
    }
}

@MainActor
private final class MusicPlaybackStateStoreSpy: MusicPlaybackStatePersisting {
    private let restoration: MusicPlaybackRestoration?
    private var preferences: MusicPlaybackPreferences?
    private(set) var saved: [MusicPlaybackRestoration] = []
    private(set) var savedProgress: [MusicPlaybackProgressCheckpoint] = []
    private(set) var savedPreferences: [MusicPlaybackPreferences] = []
    private(set) var clearCallCount = 0

    init(
        restoration: MusicPlaybackRestoration? = nil,
        preferences: MusicPlaybackPreferences? = nil
    ) {
        self.restoration = restoration
        self.preferences = preferences
    }

    func load() -> MusicPlaybackRestoration? { restoration }
    func save(_ restoration: MusicPlaybackRestoration) { saved.append(restoration) }
    func saveProgress(_ checkpoint: MusicPlaybackProgressCheckpoint) {
        savedProgress.append(checkpoint)
    }
    func clear() { clearCallCount += 1 }
    func loadPreferences() -> MusicPlaybackPreferences? { preferences }
    func savePreferences(_ preferences: MusicPlaybackPreferences) {
        self.preferences = preferences
        savedPreferences.append(preferences)
    }
}

@MainActor
private final class AudioPlaybackEngineSpy: AudioPlaybackEngine {
    private(set) var loadedURLs: [URL] = []
    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var seekPositions: [Double] = []
    private(set) var playbackRates: [Float] = []

    func load(url: URL) {
        loadedURLs.append(url)
    }

    func play() {
        playCallCount += 1
    }

    func pause() {
        pauseCallCount += 1
    }

    func seek(to seconds: Double) {
        seekPositions.append(seconds)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRates.append(rate)
    }
}

@MainActor
private final class MusicPlaybackServiceStub: MusicPlaybackServicing {
    private let missingStreamIDs: Set<UUID>
    private(set) var requestedStreamIDs: [UUID] = []
    private(set) var recordedTrackIDs: [UUID] = []
    private(set) var skippedTrackIDs: [UUID] = []
    private(set) var skippedPositions: [Double?] = []
    private(set) var skippedDurations: [Double?] = []
    private(set) var playbackUpdates: [(id: UUID, resumeSeconds: Double, completed: Bool)] = []

    init(missingStreamIDs: Set<UUID> = []) {
        self.missingStreamIDs = missingStreamIDs
    }

    func audioStreamURL(for trackID: UUID) -> URL? {
        requestedStreamIDs.append(trackID)
        guard !missingStreamIDs.contains(trackID) else { return nil }
        return URL(string: "https://media.example.test/api/audio-stream/\(trackID)?api_key=token")
    }

    func recordAudioTrackPlay(id: UUID) async throws {
        recordedTrackIDs.append(id)
    }

    func recordEntityPlaybackEvent(
        id: UUID,
        kind: PlaybackEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?
    ) async throws {
        guard kind == .skipped else { return }
        skippedTrackIDs.append(id)
        skippedPositions.append(positionSeconds)
        skippedDurations.append(durationSeconds)
    }

    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {
        playbackUpdates.append((id, resumeSeconds, completed))
    }
}

private final class TestMusicPlaybackClock: MusicPlaybackClock, @unchecked Sendable {
    private let lock = NSLock()
    private var storedNow: TimeInterval = 0

    var now: TimeInterval { lock.withLock { storedNow } }

    func advance(by interval: TimeInterval) {
        lock.withLock { storedNow += interval }
    }
}

@MainActor
private final class SuspendingMusicPlaybackServiceStub: MusicPlaybackServicing {
    private var recordingContinuation: CheckedContinuation<Void, Never>?

    func audioStreamURL(for trackID: UUID) -> URL? {
        URL(string: "https://media.example.test/api/audio-stream/\(trackID)?api_key=token")
    }

    func recordAudioTrackPlay(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            recordingContinuation = continuation
        }
    }

    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {}

    func finishRecording() {
        recordingContinuation?.resume()
        recordingContinuation = nil
    }
}
