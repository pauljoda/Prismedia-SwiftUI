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

    func testPlaybackFailureRetriesDirectStreamBeforeFullTranscode() async {
        let videoID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let service = StagedFallbackVideoPlaybackService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession()
        )
        await controller.load()

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: controller.player.currentItem
        )
        await waitForNegotiationCount(2, service: service)

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: controller.player.currentItem
        )
        await waitForNegotiationCount(3, service: service)

        let modes = await service.negotiatedModes
        XCTAssertEqual(modes, [.automatic, .directStream, .transcode])
    }

    func testNativePreflightRequestsRemuxBeforeInstallingUnplayableDirectFile() async {
        let videoID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let service = NativePreflightVideoPlaybackService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession()
        )

        await controller.load()

        let modes = await service.negotiatedModes
        XCTAssertEqual(modes, [.automatic, .directStream])
        XCTAssertEqual(controller.delivery, .remux)
        XCTAssertNotNil(controller.player.currentItem)
        XCTAssertTrue(
            controller.playbackFailureDetails.contains {
                $0.contains("native playability check")
            })
    }

    private func waitForNegotiationCount(
        _ count: Int,
        service: StagedFallbackVideoPlaybackService
    ) async {
        for _ in 0..<100 {
            if await service.negotiatedModes.count >= count { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Timed out waiting for \(count) playback negotiations")
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

private actor StagedFallbackVideoPlaybackService: VideoPlaybackServicing {
    private(set) var negotiatedModes: [VideoPlaybackNegotiationMode] = []
    private let videoID: UUID

    init(videoID: UUID) {
        self.videoID = videoID
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            mode: forceTranscode ? .transcode : .automatic,
            audioStreamIndex: nil
        )
    }

    func negotiateVideoPlayback(
        videoID: UUID,
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int?
    ) async throws -> VideoPlaybackPlan {
        negotiatedModes.append(mode)
        let delivery: VideoPlaybackDelivery =
            switch mode {
            case .automatic: .direct
            case .directStream: .remux
            case .transcode: .transcode
            }
        return VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/\(mode).m3u8")!,
            delivery: delivery,
            playSessionID: "session",
            mediaSourceID: "source",
            durationSeconds: 120
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}

private actor NativePreflightVideoPlaybackService: VideoPlaybackServicing {
    private(set) var negotiatedModes: [VideoPlaybackNegotiationMode] = []
    private let videoID: UUID

    init(videoID: UUID) {
        self.videoID = videoID
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            mode: forceTranscode ? .transcode : .automatic,
            audioStreamIndex: nil
        )
    }

    func negotiateVideoPlayback(
        videoID: UUID,
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int?
    ) async throws -> VideoPlaybackPlan {
        negotiatedModes.append(mode)
        if mode == .automatic {
            return VideoPlaybackPlan(
                videoID: self.videoID,
                url: URL(fileURLWithPath: "/dev/null"),
                delivery: .direct,
                playSessionID: "session",
                mediaSourceID: "source",
                durationSeconds: 120,
                requiresNativePlayabilityCheck: true
            )
        }
        return VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/remux.m3u8")!,
            delivery: .remux,
            playSessionID: "session",
            mediaSourceID: "source",
            durationSeconds: 120
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}
