import Foundation
import XCTest

@testable import PrismediaCore

@MainActor
final class AudiobookPlayerControllerTests: XCTestCase {
    func testAudiobookQueueStartsAtSavedPartAndReportsCanonicalBookProgress() async {
        let bookID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let tracks = [makeTrack(idSuffix: 1, duration: 100), makeTrack(idSuffix: 2, duration: 200)]
        let engine = AudiobookAudioEngineSpy()
        let service = AudiobookPlaybackServiceSpy()
        let clock = AudiobookTestClock()
        let controller = MusicPlayerController(
            engine: engine,
            service: service,
            playbackClock: clock
        )
        let context = MusicPlaybackContext(
            playbackOwnerEntityID: bookID,
            playbackOwnerTitle: "The Long Voyage",
            playbackOwnerEntityKind: .book,
            bookProgressMappings: epubMappings(bookID: bookID, tracks: tracks)
        )

        controller.play(
            tracks: tracks,
            startingAt: tracks[1].id,
            queueMode: .ordered,
            context: context,
            startSeconds: 45
        )
        controller.updatePlaybackProgress(
            elapsedTime: 45,
            duration: tracks[1].duration,
            isAdvancing: true
        )
        clock.advance(by: 15)
        controller.updateElapsedTime(51)
        await controller.flushPendingPlaybackReports()

        XCTAssertEqual(controller.context, context)
        XCTAssertEqual(engine.seekPositions, [45])
        XCTAssertEqual(service.progressUpdates.count, 1)
        XCTAssertEqual(service.progressUpdates[0].entityID, bookID)
        XCTAssertEqual(service.progressUpdates[0].request.currentEntityID, bookID)
        XCTAssertEqual(service.progressUpdates[0].request.unit, .cfi)
        XCTAssertEqual(service.progressUpdates[0].request.index, 6_275)
        XCTAssertEqual(service.progressUpdates[0].request.total, 10_000)
        XCTAssertEqual(service.progressUpdates[0].request.activitySeconds, 15)
        XCTAssertEqual(service.progressUpdates[0].request.activityKind, .listening)
    }

    func testAudiobookFinalPartCompletionMarksBookCompleteAndClearsResumeCursor() async {
        let bookID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let tracks = [makeTrack(idSuffix: 1, duration: 100), makeTrack(idSuffix: 2, duration: 200)]
        let service = AudiobookPlaybackServiceSpy()
        let clock = AudiobookTestClock()
        let controller = MusicPlayerController(
            engine: AudiobookAudioEngineSpy(),
            service: service,
            playbackClock: clock
        )

        controller.play(
            tracks: tracks,
            startingAt: tracks[1].id,
            context: MusicPlaybackContext(
                playbackOwnerEntityID: bookID,
                playbackOwnerTitle: "The Long Voyage",
                playbackOwnerEntityKind: .book,
                bookProgressMappings: epubMappings(bookID: bookID, tracks: tracks)
            )
        )
        controller.updatePlaybackProgress(
            elapsedTime: 0,
            duration: tracks[1].duration,
            isAdvancing: true
        )

        clock.advance(by: 12)
        await controller.handlePlaybackEnded()
        await controller.flushPendingPlaybackReports()
        await controller.flushAudiobookProgress()

        XCTAssertEqual(service.progressUpdates.count, 1)
        XCTAssertEqual(service.progressUpdates[0].entityID, bookID)
        XCTAssertEqual(service.progressUpdates[0].request.index, 10_000)
        XCTAssertEqual(service.progressUpdates[0].request.completed, true)
        XCTAssertEqual(service.progressUpdates[0].request.activitySeconds, 12)
        XCTAssertEqual(service.progressUpdates[0].request.activityKind, .listening)
        XCTAssertTrue(service.recordedTrackIDs.isEmpty)
        XCTAssertFalse(controller.isPlaying)
    }

    func testAudiobookRestorationKeepsOwnerAndSourceOrderWithoutShuffle() {
        let tracks = [makeTrack(idSuffix: 1, duration: 100), makeTrack(idSuffix: 2, duration: 200)]
        let context = MusicPlaybackContext(
            playbackOwnerEntityID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            playbackOwnerTitle: "The Long Voyage",
            playbackOwnerEntityKind: .book
        )
        let restoration = MusicPlaybackRestoration(
            tracks: tracks,
            orderedTrackIDs: [tracks[1].id, tracks[0].id],
            currentTrackID: tracks[1].id,
            repeatMode: .all,
            isShuffled: true,
            elapsedTime: 45,
            context: context
        )
        let controller = MusicPlayerController(
            engine: AudiobookAudioEngineSpy(),
            service: AudiobookPlaybackServiceSpy(),
            stateStore: AudiobookPlaybackStateStore(restoration: restoration)
        )

        controller.restoreIfNeeded()

        XCTAssertEqual(controller.context, context)
        XCTAssertEqual(controller.queue.orderedTracks.map(\.id), tracks.map(\.id))
        XCTAssertFalse(controller.queue.isShuffled)
        XCTAssertEqual(controller.currentTrack?.id, tracks[1].id)
    }

    private func makeTrack(idSuffix: Int, duration: Double) -> MusicTrack {
        MusicTrack(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSuffix))!,
            title: "Part \(idSuffix)",
            album: "The Long Voyage",
            duration: duration,
            sortOrder: idSuffix - 1
        )
    }

    private func epubMappings(
        bookID: UUID,
        tracks: [MusicTrack]
    ) -> [BookProgressTrackMapping] {
        tracks.enumerated().map { index, track in
            BookProgressTrackMapping(
                trackID: track.id,
                currentEntityID: bookID,
                unit: .cfi,
                startIndex: index * 5_000,
                endIndex: (index + 1) * 5_000,
                total: 10_000,
                mode: .paged
            )
        }
    }
}

@MainActor
private final class AudiobookAudioEngineSpy: AudioPlaybackEngine {
    private(set) var seekPositions: [Double] = []

    func load(url: URL) {}
    func play() {}
    func pause() {}
    func seek(to seconds: Double) { seekPositions.append(seconds) }
    func setPlaybackRate(_ rate: Float) {}
}

@MainActor
private final class AudiobookPlaybackServiceSpy: MusicPlaybackServicing {
    struct ProgressUpdate: Equatable {
        let entityID: UUID
        let request: EntityProgressUpdateRequest
    }

    private(set) var recordedTrackIDs: [UUID] = []
    private(set) var progressUpdates: [ProgressUpdate] = []

    func audioStreamURL(for trackID: UUID) -> URL? {
        URL(string: "https://example.com/audio/\(trackID)")
    }

    func recordAudioTrackPlay(id: UUID) async throws {
        recordedTrackIDs.append(id)
    }

    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {
    }

    func updateEntityProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        progressUpdates.append(.init(entityID: id, request: request))
    }
}

private final class AudiobookTestClock: MusicPlaybackClock, @unchecked Sendable {
    private let lock = NSLock()
    private var storedNow: TimeInterval = 0

    var now: TimeInterval { lock.withLock { storedNow } }

    func advance(by interval: TimeInterval) {
        lock.withLock { storedNow += interval }
    }
}

@MainActor
private final class AudiobookPlaybackStateStore: MusicPlaybackStatePersisting {
    private let restoration: MusicPlaybackRestoration

    init(restoration: MusicPlaybackRestoration) {
        self.restoration = restoration
    }

    func load() -> MusicPlaybackRestoration? { restoration }
    func save(_ restoration: MusicPlaybackRestoration) {}
    func clear() {}
}
