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
    private var activityClock = ConsumptionActivityClock()

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
        activityClock = ConsumptionActivityClock()
    }

    func playbackStarted(positionSeconds: Double) {
        guard let context, !isTerminal else { return }
        activityClock.start(at: clock.now)
        guard !hasStarted else { return }
        hasStarted = true
        record(.started, context: context, positionSeconds: positionSeconds)
    }

    func observePlayback(positionSeconds: Double, isPlaying: Bool) {
        guard hasStarted, !isTerminal, let context else { return }
        guard isPlaying else {
            playbackPaused(positionSeconds: positionSeconds)
            return
        }
        activityClock.start(at: clock.now)
        guard heartbeatIsDue, playbackMovedMeaningfully(to: positionSeconds) else { return }
        record(
            .progress,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activityClock.take(at: clock.now)
        )
    }

    func playbackPaused(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        let activitySeconds = activityClock.stop(at: clock.now)
        guard activitySeconds != nil else { return }
        record(
            .progress,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activitySeconds
        )
    }

    func didSeek(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        record(
            .progress,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activityClock.take(at: clock.now)
        )
    }

    func flushProgress(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        record(
            .progress,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activityClock.stop(at: clock.now)
        )
    }

    func stop(positionSeconds: Double) {
        guard hasStarted, !isTerminal, let context else { return }
        isTerminal = true
        record(
            .stopped,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activityClock.stop(at: clock.now)
        )
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
            completed: true,
            activitySeconds: activityClock.stop(at: clock.now)
        )
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
        record(
            .stopped,
            context: context,
            positionSeconds: positionSeconds,
            activitySeconds: activityClock.stop(at: clock.now)
        )
    }

    private func record(
        _ event: VideoPlaybackEvent,
        context: VideoPlaybackReportContext,
        positionSeconds: Double,
        completed: Bool? = nil,
        activitySeconds: Double? = nil
    ) {
        let report = context.report(
            positionSeconds: positionSeconds,
            completed: completed,
            activitySeconds: activitySeconds
        )
        lastReportTime = clock.now
        lastReportedPosition = max(0, positionSeconds)
        enqueue { service in
            try await service.reportVideoPlayback(event, report: report)
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
