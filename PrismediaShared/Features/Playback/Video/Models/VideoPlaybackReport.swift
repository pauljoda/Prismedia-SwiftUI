import Foundation

public struct VideoPlaybackReport: Encodable, Hashable, Sendable {
    public let videoID: UUID
    public let mediaSourceID: String
    public let playSessionID: String
    public let positionTicks: Int64
    public let isPaused: Bool
    public let isMuted: Bool

    public init(
        videoID: UUID,
        mediaSourceID: String,
        playSessionID: String,
        positionSeconds: Double,
        isPaused: Bool,
        isMuted: Bool
    ) {
        self.videoID = videoID
        self.mediaSourceID = mediaSourceID
        self.playSessionID = playSessionID
        let safeSeconds = positionSeconds.isFinite ? max(0, positionSeconds) : 0
        positionTicks = Int64((safeSeconds * 10_000_000).rounded())
        self.isPaused = isPaused
        self.isMuted = isMuted
    }

    private enum CodingKeys: String, CodingKey {
        case videoID = "ItemId"
        case mediaSourceID = "MediaSourceId"
        case playSessionID = "PlaySessionId"
        case positionTicks = "PositionTicks"
        case isPaused = "IsPaused"
        case isMuted = "IsMuted"
    }
}
