import Foundation

public struct MusicPlaybackProgressCheckpoint: Codable, Equatable, Sendable {
    public let currentTrackID: UUID?
    public let elapsedTime: Double
    public let audiobookCompleted: Bool?

    public init(
        currentTrackID: UUID?,
        elapsedTime: Double,
        audiobookCompleted: Bool?
    ) {
        self.currentTrackID = currentTrackID
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        self.audiobookCompleted = audiobookCompleted
    }
}
