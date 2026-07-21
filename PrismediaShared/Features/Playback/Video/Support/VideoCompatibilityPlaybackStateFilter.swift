import Foundation

struct VideoCompatibilityPlaybackStateFilter {
    private static let timelineRefreshInterval = 0.5
    private static let seekProtectionDuration = 2.0
    private static let seekTargetTolerance = 1.0

    private var lastPublishedState: VideoCompatibilityPlaybackState?
    private var lastPublicationTime: TimeInterval?
    private var pendingSeekTarget: Double?
    private var seekProtectionDeadline: TimeInterval?

    mutating func beginSeek(to target: Double, at time: TimeInterval) {
        pendingSeekTarget = target
        seekProtectionDeadline = time + Self.seekProtectionDuration
        lastPublishedState?.currentTime = target
    }

    mutating func stateToPublish(
        _ candidate: VideoCompatibilityPlaybackState,
        at time: TimeInterval
    ) -> VideoCompatibilityPlaybackState? {
        var resolved = candidate
        applyPendingSeek(to: &resolved, candidateTime: candidate.currentTime, at: time)

        guard let lastPublishedState, let lastPublicationTime else {
            record(resolved, at: time)
            return resolved
        }
        let playbackStateChanged =
            resolved.isPlaying != lastPublishedState.isPlaying
            || resolved.isWaiting != lastPublishedState.isWaiting
        let durationChanged = abs(resolved.duration - lastPublishedState.duration) >= 0.5
        let timelineRefreshIsDue =
            time - lastPublicationTime >= Self.timelineRefreshInterval
            && abs(resolved.currentTime - lastPublishedState.currentTime) >= 0.01
        guard playbackStateChanged || durationChanged || timelineRefreshIsDue else { return nil }

        record(resolved, at: time)
        return resolved
    }

    private mutating func applyPendingSeek(
        to state: inout VideoCompatibilityPlaybackState,
        candidateTime: Double,
        at time: TimeInterval
    ) {
        guard let pendingSeekTarget, let seekProtectionDeadline else { return }
        if abs(candidateTime - pendingSeekTarget) <= Self.seekTargetTolerance
            || time >= seekProtectionDeadline
        {
            self.pendingSeekTarget = nil
            self.seekProtectionDeadline = nil
            return
        }
        state.currentTime = pendingSeekTarget
    }

    private mutating func record(
        _ state: VideoCompatibilityPlaybackState,
        at time: TimeInterval
    ) {
        lastPublishedState = state
        lastPublicationTime = time
    }
}
