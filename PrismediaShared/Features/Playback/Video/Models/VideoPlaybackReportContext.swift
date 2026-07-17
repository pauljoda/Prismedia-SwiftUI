import Foundation

struct VideoPlaybackReportContext: Hashable, Sendable {
    let videoID: UUID
    let mediaSourceID: String
    let playSessionID: String
    let durationSeconds: Double

    init(plan: VideoPlaybackPlan) {
        videoID = plan.videoID
        mediaSourceID = plan.mediaSourceID
        playSessionID = plan.playSessionID
        durationSeconds = plan.durationSeconds
    }

    func report(positionSeconds: Double, isPaused: Bool) -> VideoPlaybackReport {
        VideoPlaybackReport(
            videoID: videoID,
            mediaSourceID: mediaSourceID,
            playSessionID: playSessionID,
            positionSeconds: positionSeconds,
            isPaused: isPaused,
            isMuted: false
        )
    }
}
