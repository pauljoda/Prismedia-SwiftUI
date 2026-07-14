import Foundation

public struct PlaybackStatisticsSnapshot: Sendable {
    public var response: PlaybackStatisticsResponse?
    public var thumbnailsByID: [UUID: EntityThumbnail]
    public var state: PlaybackStatisticsState

    public init(
        response: PlaybackStatisticsResponse? = nil,
        thumbnailsByID: [UUID: EntityThumbnail] = [:],
        state: PlaybackStatisticsState = .idle
    ) {
        self.response = response
        self.thumbnailsByID = thumbnailsByID
        self.state = state
    }
}
