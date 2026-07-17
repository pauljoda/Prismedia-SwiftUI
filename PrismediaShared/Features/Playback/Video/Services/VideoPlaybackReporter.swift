import Foundation

@MainActor
final class VideoPlaybackReporter {
    private let service: (any VideoPlaybackReporting)?
    private let clock: any VideoPlaybackClock
    private let heartbeatInterval: TimeInterval
    private let minimumMovement: Double
    private var context: VideoPlaybackReportContext?
    private var hasStarted = false
    private var isTerminal = false
    private var lastReportTime: TimeInterval?
    private var lastReportedPosition = 0.0
    private var pendingReport: Task<Void, Never>?

    init(
        service: (any VideoPlaybackReporting)?,
        clock: any VideoPlaybackClock = SystemVideoPlaybackClock(),
        heartbeatInterval: TimeInterval = 10,
        minimumMovement: Double = 3
    ) {
        self.service = service
        self.clock = clock
        self.heartbeatInterval = heartbeatInterval
        self.minimumMovement = minimumMovement
    }

    func install(plan: VideoPlaybackPlan, positionSeconds: Double) {
        stopCurrentSessionForReplacement(positionSeconds: positionSeconds)
        context = VideoPlaybackReportContext(plan: plan)
        hasStarted = false
        isTerminal = false
        lastReportTime = nil
        lastReportedPosition = max(0, positionSeconds)
    }

    func playbackStarted(positionSeconds: Double) {
        guard let context, !hasStarted, !isTerminal else { return }
        hasStarted = true
        record(.started, context: context, positionSeconds: positionSeconds)
    }

    func observePlayback(positionSeconds: Double, isPlaying: Bool) {
        guard hasStarted, !isTerminal, isPlaying, let context else { return }
        guard heartbeatIsDue, playbackMovedMeaningfully(to: positionSeconds) else { return }
        record(.progress, context: context, positionSeconds: positionSeconds)
    }

    func didSeek(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        record(.progress, context: context, positionSeconds: positionSeconds)
    }

    func flushProgress(positionSeconds: Double, isPaused: Bool) {
        guard hasStarted, !isTerminal, let context else { return }
        record(.progress, context: context, positionSeconds: positionSeconds, isPaused: isPaused)
    }

    func stop(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        isTerminal = true
        record(.stopped, context: context, positionSeconds: positionSeconds, isPaused: true)
    }

    func complete() {
        guard !isTerminal, let context else { return }
        hasStarted = true
        isTerminal = true
        let completionPosition = context.durationSeconds.isFinite && context.durationSeconds > 0
            ? max(context.durationSeconds, lastReportedPosition)
            : lastReportedPosition
        record(
            .stopped,
            context: context,
            positionSeconds: completionPosition,
            isPaused: true
        )
        markPlayed(videoID: context.videoID)
    }

    func waitForPendingReports() async {
        await pendingReport?.value
    }

    private var heartbeatIsDue: Bool {
        guard let lastReportTime else { return true }
        return clock.now - lastReportTime >= heartbeatInterval
    }

    private func playbackMovedMeaningfully(to positionSeconds: Double) -> Bool {
        abs(positionSeconds - lastReportedPosition) > minimumMovement
    }

    private func stopCurrentSessionForReplacement(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        record(.stopped, context: context, positionSeconds: positionSeconds, isPaused: true)
    }

    private func record(
        _ event: VideoPlaybackEvent,
        context: VideoPlaybackReportContext,
        positionSeconds: Double,
        isPaused: Bool = false
    ) {
        let report = context.report(positionSeconds: positionSeconds, isPaused: isPaused)
        lastReportTime = clock.now
        lastReportedPosition = max(0, positionSeconds)
        enqueue { service in
            try await service.reportVideoPlayback(event, report: report)
        }
    }

    private func markPlayed(videoID: UUID) {
        enqueue { service in
            try await service.markVideoPlayed(videoID: videoID)
        }
    }

    private func enqueue(
        _ operation: @escaping @Sendable (any VideoPlaybackReporting) async throws -> Void
    ) {
        guard let service else { return }
        let previous = pendingReport
        pendingReport = Task {
            await previous?.value
            try? await operation(service)
        }
    }
}
