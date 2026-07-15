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
        let tracks = (1...1_000).map(makeTrack(idSuffix:))
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

    private func makeTrack(idSuffix: Int) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSuffix))!,
            title: "Track \(idSuffix)",
            artist: "Artist",
            album: "Album",
            sortOrder: idSuffix - 1
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
    private(set) var recordedTrackIDs: [UUID] = []

    init(missingStreamIDs: Set<UUID> = []) {
        self.missingStreamIDs = missingStreamIDs
    }

    func audioStreamURL(for trackID: UUID) -> URL? {
        guard !missingStreamIDs.contains(trackID) else { return nil }
        return URL(string: "https://media.example.test/api/audio-stream/\(trackID)?api_key=token")
    }

    func recordAudioTrackPlay(id: UUID) async throws {
        recordedTrackIDs.append(id)
    }

    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {}
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
