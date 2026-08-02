import Foundation

public struct ConsumptionStatisticsSnapshot: Sendable {
    public var response: ConsumptionStatisticsResponse?
    public var thumbnailsByID: [UUID: EntityThumbnail]
    public var state: ConsumptionStatisticsState

    public init(
        response: ConsumptionStatisticsResponse? = nil,
        thumbnailsByID: [UUID: EntityThumbnail] = [:],
        state: ConsumptionStatisticsState = .idle
    ) {
        self.response = response
        self.thumbnailsByID = thumbnailsByID
        self.state = state
    }
}
