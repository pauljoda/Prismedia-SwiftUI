import Foundation
import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackReporterTests: XCTestCase {
    func testStartedReportCarriesNegotiatedSessionIdentifiersAndCurrentPosition() async {
        let service = ReportingSpy()
        let clock = TestVideoPlaybackClock()
        let reporter = VideoPlaybackReporter(service: service, clock: clock)
        let plan = makePlan(playSessionID: "session-1", mediaSourceID: "source-1")

        reporter.install(plan: plan, positionSeconds: 7)
        reporter.playbackStarted(positionSeconds: 7)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started])
        XCTAssertEqual(reports.first?.report.videoID, plan.videoID)
        XCTAssertEqual(reports.first?.report.playSessionID, "session-1")
        XCTAssertEqual(reports.first?.report.mediaSourceID, "source-1")
        XCTAssertEqual(reports.first?.report.positionTicks, 70_000_000)
    }

    func testHeartbeatWaitsTenSecondsAndMeaningfulPlaybackMovement() async {
        let service = ReportingSpy()
        let clock = TestVideoPlaybackClock()
        let reporter = VideoPlaybackReporter(service: service, clock: clock)
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)

        clock.advance(by: 9.9)
        reporter.observePlayback(positionSeconds: 9.9, isPlaying: true)
        clock.advance(by: 0.1)
        reporter.observePlayback(positionSeconds: 10, isPlaying: true)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .progress])
        XCTAssertEqual(reports.last?.report.positionTicks, 100_000_000)
    }

    func testHeartbeatDoesNotReportPausedOrUnchangedPlayback() async {
        let service = ReportingSpy()
        let clock = TestVideoPlaybackClock()
        let reporter = VideoPlaybackReporter(service: service, clock: clock)
        reporter.install(plan: makePlan(), positionSeconds: 5)
        reporter.playbackStarted(positionSeconds: 5)

        clock.advance(by: 10)
        reporter.observePlayback(positionSeconds: 5, isPlaying: true)
        clock.advance(by: 10)
        reporter.observePlayback(positionSeconds: 15, isPlaying: false)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started])
    }

    func testSeekReportsImmediatelyAndResetsHeartbeatWindow() async {
        let service = ReportingSpy()
        let clock = TestVideoPlaybackClock()
        let reporter = VideoPlaybackReporter(service: service, clock: clock)
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)

        clock.advance(by: 2)
        reporter.didSeek(positionSeconds: 42)
        clock.advance(by: 8)
        reporter.observePlayback(positionSeconds: 50, isPlaying: true)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .progress])
        XCTAssertEqual(reports.last?.report.positionTicks, 420_000_000)
    }

    func testBackgroundFlushReportsCurrentPausedStateWithoutEndingSession() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)

        reporter.flushProgress(positionSeconds: 27, isPaused: true)
        reporter.stop(positionSeconds: 29)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .progress, .stopped])
        XCTAssertEqual(reports[1].report.positionTicks, 270_000_000)
        XCTAssertTrue(reports[1].report.isPaused)
        XCTAssertEqual(reports[2].report.positionTicks, 290_000_000)
    }

    func testStopFlushesFinalPositionOnlyOnce() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)

        reporter.stop(positionSeconds: 31)
        reporter.stop(positionSeconds: 32)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped])
        XCTAssertEqual(reports.last?.report.positionTicks, 310_000_000)
    }

    func testCompletionStopsAtDurationWithoutAnExplicitPlayedMutation() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)

        reporter.complete()
        reporter.stop(positionSeconds: 120)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped])
        XCTAssertEqual(reports.last?.report.positionTicks, 1_200_000_000)
    }

    func testCompletionKeepsFinalStopAtDurationAfterThresholdProgress() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)
        reporter.playbackStarted(positionSeconds: 0)
        reporter.didSeek(positionSeconds: 110)

        reporter.complete()
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .progress, .stopped])
        XCTAssertEqual(reports.last?.report.positionTicks, 1_200_000_000)
    }

    func testCompletionStillStopsAtDurationWhenPlayerStateNotificationWasMissed() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)

        reporter.complete()
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.stopped])
        XCTAssertEqual(reports.first?.report.positionTicks, 1_200_000_000)
    }

    func testReportingFailureDoesNotPreventLaterStopOrCompletion() async {
        let service = ReportingSpy(failingEvents: [.started])
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)

        reporter.playbackStarted(positionSeconds: 0)
        reporter.complete()
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped])
    }

    func testCancelledReportDoesNotCancelTheFollowingStop() async {
        let service = ReportingSpy(cancellingEvents: [.started])
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(plan: makePlan(), positionSeconds: 0)

        reporter.playbackStarted(positionSeconds: 0)
        reporter.stop(positionSeconds: 8)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped])
        XCTAssertEqual(reports.last?.report.positionTicks, 80_000_000)
    }

    func testInstallingReplacementStopsStartedSessionBeforeUsingNewIdentifiers() async {
        let service = ReportingSpy()
        let reporter = VideoPlaybackReporter(service: service, clock: TestVideoPlaybackClock())
        reporter.install(
            plan: makePlan(playSessionID: "old-session", mediaSourceID: "old-source"),
            positionSeconds: 0
        )
        reporter.playbackStarted(positionSeconds: 0)

        reporter.install(
            plan: makePlan(playSessionID: "new-session", mediaSourceID: "new-source"),
            positionSeconds: 18
        )
        reporter.playbackStarted(positionSeconds: 18)
        await reporter.waitForPendingReports()

        let reports = await service.reports
        XCTAssertEqual(reports.map(\.event), [.started, .stopped, .started])
        XCTAssertEqual(reports.map(\.report.playSessionID), ["old-session", "old-session", "new-session"])
        XCTAssertEqual(reports[1].report.positionTicks, 180_000_000)
    }

    private func makePlan(
        playSessionID: String = "session",
        mediaSourceID: String = "source"
    ) -> VideoPlaybackPlan {
        VideoPlaybackPlan(
            videoID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            url: URL(string: "https://media.example.test/video.mp4")!,
            delivery: .direct,
            playSessionID: playSessionID,
            mediaSourceID: mediaSourceID,
            durationSeconds: 120
        )
    }
}

private final class TestVideoPlaybackClock: VideoPlaybackClock, @unchecked Sendable {
    private let lock = NSLock()
    private var storedNow: TimeInterval = 0

    var now: TimeInterval { lock.withLock { storedNow } }

    func advance(by interval: TimeInterval) {
        lock.withLock { storedNow += interval }
    }
}

private actor ReportingSpy: VideoPlaybackReporting {
    struct RecordedReport: Sendable {
        let event: VideoPlaybackEvent
        let report: VideoPlaybackReport
    }

    private(set) var reports: [RecordedReport] = []
    private let failingEvents: Set<VideoPlaybackEvent>
    private let cancellingEvents: Set<VideoPlaybackEvent>

    init(
        failingEvents: Set<VideoPlaybackEvent> = [],
        cancellingEvents: Set<VideoPlaybackEvent> = []
    ) {
        self.failingEvents = failingEvents
        self.cancellingEvents = cancellingEvents
    }

    func reportVideoPlayback(_ event: VideoPlaybackEvent, report: VideoPlaybackReport) async throws {
        reports.append(.init(event: event, report: report))
        if cancellingEvents.contains(event) { throw CancellationError() }
        if failingEvents.contains(event) { throw URLError(.cannotConnectToHost) }
    }
}
