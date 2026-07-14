import Foundation
import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackControllerTests: XCTestCase {
    func testAudioSessionFailureDoesNotPreventPlaybackNegotiation() async {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let service = VideoPlaybackServiceSpy(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession()
        )

        await controller.load()

        let negotiatedVideoIDs = await service.negotiatedVideoIDs
        XCTAssertEqual(negotiatedVideoIDs, [videoID])
        XCTAssertNotNil(controller.player.currentItem)
        XCTAssertNil(controller.errorMessage)
    }

    func testCompletingCurrentPlayerItemNotifiesPlaybackOwner() async {
        let videoID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: VideoPlaybackServiceSpy(videoID: videoID),
            audioSession: FailingVideoAudioSession()
        )
        let completed = expectation(description: "playback completion")
        controller.onPlaybackCompleted = { completed.fulfill() }
        await controller.load()

        NotificationCenter.default.post(
            name: .AVPlayerItemDidPlayToEndTime,
            object: controller.player.currentItem
        )

        await fulfillment(of: [completed], timeout: 1)
    }
}

private struct FailingVideoAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {
        throw NSError(domain: NSOSStatusErrorDomain, code: -50)
    }
}

private actor VideoPlaybackServiceSpy: VideoPlaybackServicing {
    private(set) var negotiatedVideoIDs: [UUID] = []
    private let videoID: UUID

    init(videoID: UUID) {
        self.videoID = videoID
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        negotiatedVideoIDs.append(videoID)
        return VideoPlaybackPlan(
            videoID: videoID,
            url: URL(string: "https://media.example.test/video.mp4")!,
            delivery: .direct,
            playSessionID: "session",
            mediaSourceID: "source",
            durationSeconds: 120
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}
