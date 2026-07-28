import Foundation

public struct VideoPlaybackProgressSnapshot: Equatable, Sendable {
    public let videoID: UUID
    public let positionSeconds: Double
    public let durationSeconds: Double

    public init(
        videoID: UUID,
        positionSeconds: Double,
        durationSeconds: Double
    ) {
        self.videoID = videoID
        self.positionSeconds = max(0, positionSeconds)
        self.durationSeconds = max(0, durationSeconds)
    }
}
