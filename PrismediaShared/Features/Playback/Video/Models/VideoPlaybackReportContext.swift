import Foundation

struct VideoPlaybackReportContext: Hashable, Sendable {
    let entityID: UUID
    let sessionID: String
    let durationSeconds: Double

    init(plan: VideoPlaybackPlan) {
        entityID = plan.videoID
        sessionID = plan.sessionID
        durationSeconds = plan.durationSeconds
    }

    func report(positionSeconds: Double, completed: Bool? = nil) -> VideoPlaybackReport {
        VideoPlaybackReport(
            entityID: entityID,
            sessionID: sessionID,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            completed: completed
        )
    }
}
