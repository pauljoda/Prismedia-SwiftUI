import Foundation

public struct PlaybackStatisticsResponse: Decodable, Equatable, Sendable {
    public let from: Date
    public let to: Date
    public let totalEvents: Int
    public let completedCount: Int
    public let skippedCount: Int
    public let distinctEntityCount: Int
    public let topEntities: [PlaybackStatisticsEntity]
    public let recentEvents: [PlaybackStatisticsEvent]
    public let dailyEvents: [PlaybackStatisticsBucket]
}
