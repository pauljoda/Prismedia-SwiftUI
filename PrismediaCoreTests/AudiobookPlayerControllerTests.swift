import Foundation
import XCTest

@testable import PrismediaCore

@MainActor
final class AudiobookPlayerControllerTests: XCTestCase {
    func testAudiobookQueueStartsAtSavedPartAndReportsBookAbsoluteProgress() async {
        let bookID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let tracks = [makeTrack(idSuffix: 1, duration: 100), makeTrack(idSuffix: 2, duration: 200)]
        let engine = AudiobookAudioEngineSpy()
        let service = AudiobookPlaybackServiceSpy()
        let controller = MusicPlayerController(engine: engine, service: service)
        let context = MusicPlaybackContext(
            playbackOwnerEntityID: bookID,
            playbackOwnerTitle: "The Long Voyage",
            playbackOwnerEntityKind: .book
        )

        controller.play(
            tracks: tracks,
            startingAt: tracks[1].id,
            queueMode: .ordered,
            context: context,
            startSeconds: 45
        )
        controller.updateElapsedTime(51)
        await controller.flushPendingPlaybackReports()

        XCTAssertEqual(controller.context, context)
        XCTAssertEqual(engine.seekPositions, [45])
        XCTAssertEqual(
            service.playbackUpdates,
            [EntityPlaybackProgressUpdate(entityID: bookID, resumeSeconds: 151, completed: false)]
        )
    }

    func testAudiobookFinalPartCompletionMarksBookCompleteAndClearsResumeCursor() async {
        let bookID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let tracks = [makeTrack(idSuffix: 1, duration: 100), makeTrack(idSuffix: 2, duration: 200)]
        let service = AudiobookPlaybackServiceSpy()
        let controller = MusicPlayerController(engine: AudiobookAudioEngineSpy(), service: service)

        controller.play(
            tracks: tracks,
            startingAt: tracks[1].id,
            context: MusicPlaybackContext(
                playbackOwnerEntityID: bookID,
                playbackOwnerTitle: "The Long Voyage",
                playbackOwnerEntityKind: .book
            )
        )

        await controller.handlePlaybackEnded()
        await controller.flushPendingPlaybackReports()
        await controller.flushAudiobookProgress()

        XCTAssertEqual(
            service.playbackUpdates.last,
            EntityPlaybackProgressUpdate(entityID: bookID, resumeSeconds: 0, completed: true)
        )
        XCTAssertTrue(service.recordedTrackIDs.isEmpty)
        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(service.playbackUpdates.count, 1)
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
}

@MainActor
private final class AudiobookAudioEngineSpy: AudioPlaybackEngine {
    private(set) var seekPositions: [Double] = []

    func load(url: URL) {}
    func play() {}
    func pause() {}
    func seek(to seconds: Double) { seekPositions.append(seconds) }
}

@MainActor
private final class AudiobookPlaybackServiceSpy: MusicPlaybackServicing {
    private(set) var recordedTrackIDs: [UUID] = []
    private(set) var playbackUpdates: [EntityPlaybackProgressUpdate] = []

    func audioStreamURL(for trackID: UUID) -> URL? {
        URL(string: "https://example.com/audio/\(trackID)")
    }

    func recordAudioTrackPlay(id: UUID) async throws {
        recordedTrackIDs.append(id)
    }

    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {
        playbackUpdates.append(
            EntityPlaybackProgressUpdate(
                entityID: id,
                resumeSeconds: resumeSeconds,
                completed: completed
            )
        )
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
