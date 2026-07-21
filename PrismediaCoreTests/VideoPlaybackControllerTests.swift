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

    func testDisplayCriteriaArePreparedBeforePlayerItemInstallationAndResetOnStop() async {
        let videoID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let metadata = VideoPlaybackDisplayMetadata(
            dynamicRange: .dolbyVision,
            frameRate: 23.976,
            width: 3_840,
            height: 2_160,
            dolbyVisionProfile: 8
        )
        let service = DisplayMetadataVideoPlaybackService(videoID: videoID, metadata: metadata)
        var controller: VideoPlaybackController!
        var preparedMetadata: VideoPlaybackDisplayMetadata?
        var didReset = false
        let displayCriteria = VideoDisplayCriteriaIntegration(
            prepare: { value in
                preparedMetadata = value
                XCTAssertNil(controller.player.currentItem)
            },
            reset: { didReset = true }
        )
        controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession(),
            displayCriteria: displayCriteria
        )

        await controller.load()

        XCTAssertEqual(preparedMetadata, metadata)
        XCTAssertNotNil(controller.player.currentItem)

        controller.stop()

        XCTAssertTrue(didReset)
    }

    func testCompatibilityPlanSkipsAVPlayerAndRoutesTransportCommands() async {
        let videoID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let service = CompatibilityVideoPlaybackService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession()
        )
        var playedRate: Float?
        var seekTime: Double?
        var stopped = false

        await controller.load(resumeAt: 42)
        controller.attachCompatibilityPlayback(
            VideoCompatibilityPlaybackCommands(
                play: { playedRate = $0 },
                pause: {},
                seek: { seekTime = $0 },
                stop: { stopped = true },
                setRate: { _ in },
                selectAudioStream: { _ in }
            )
        )

        XCTAssertEqual(controller.renderer, .compatibility)
        XCTAssertNil(controller.player.currentItem)
        XCTAssertEqual(controller.compatibilityPlaybackRequest?.resumeTime, 42)

        controller.play()
        controller.seek(to: 73)
        controller.stop()

        XCTAssertEqual(playedRate, 1)
        XCTAssertEqual(seekTime, 73)
        XCTAssertTrue(stopped)
    }

    func testCompatibilityPlaybackReportsItsFinalResumePosition() async {
        let videoID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let service = CompatibilityVideoPlaybackService(videoID: videoID)
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: service,
            audioSession: FailingVideoAudioSession()
        )

        await controller.load()
        controller.compatibilityPlaybackDidUpdate(
            currentTime: 12,
            duration: 120,
            isPlaying: true,
            isWaiting: false
        )
        controller.stop()
        await controller.waitForPendingPlaybackReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped])
        XCTAssertEqual(reports.last?.report.positionTicks, 120_000_000)
    }

    func testCompatibilityShuttleUsesDoubleSpeedUntilTheHoldEnds() async {
        let videoID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        let controller = VideoPlaybackController(
            videoID: videoID,
            service: CompatibilityVideoPlaybackService(videoID: videoID),
            audioSession: FailingVideoAudioSession()
        )
        var playedRates: [Float] = []

        await controller.load()
        controller.attachCompatibilityPlayback(
            VideoCompatibilityPlaybackCommands(
                play: { playedRates.append($0) },
                pause: {},
                seek: { _ in },
                stop: {},
                setRate: { _ in },
                selectAudioStream: { _ in }
            )
        )
        controller.compatibilityPlaybackDidUpdate(
            currentTime: 10,
            duration: 120,
            isPlaying: true,
            isWaiting: false
        )

        controller.beginShuttle(on: .right)
        controller.endShuttle()

        XCTAssertEqual(playedRates, [2, 1])
        XCTAssertNil(controller.shuttleSide)
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

private actor CompatibilityVideoPlaybackService: VideoPlaybackServicing, VideoPlaybackReporting {
    struct RecordedReport: Sendable {
        let event: VideoPlaybackEvent
        let report: VideoPlaybackReport
    }

    private let videoID: UUID
    private(set) var reports: [RecordedReport] = []

    init(videoID: UUID) {
        self.videoID = videoID
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/malformed-hdr.mkv?api_key=token")!,
            delivery: .direct,
            playSessionID: "compatibility-session",
            mediaSourceID: "compatibility-source",
            durationSeconds: 120,
            renderer: .compatibility
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }

    func reportVideoPlayback(
        _ event: VideoPlaybackEvent,
        report: VideoPlaybackReport
    ) async throws {
        reports.append(RecordedReport(event: event, report: report))
    }
}

private actor DisplayMetadataVideoPlaybackService: VideoPlaybackServicing {
    private let videoID: UUID
    private let metadata: VideoPlaybackDisplayMetadata

    init(videoID: UUID, metadata: VideoPlaybackDisplayMetadata) {
        self.videoID = videoID
        self.metadata = metadata
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/dolby-vision.m3u8")!,
            delivery: .remux,
            playSessionID: "display-session",
            mediaSourceID: "display-source",
            durationSeconds: 120,
            displayMetadata: metadata
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
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
