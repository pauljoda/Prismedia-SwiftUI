import Foundation

public struct PlaybackStatisticsResponse: Decodable, Equatable, Sendable {
    public let from: Date
    public let to: Date
    public let totalEvents: Int
    public let accessedCount: Int
    public let completedCount: Int
    public let skippedCount: Int
    public let distinctEntityCount: Int
    public let activeSeconds: Double
    public let viewingSeconds: Double
    public let readingSeconds: Double
    public let listeningSeconds: Double
    public let topEntities: [PlaybackStatisticsEntity]
    public let recentEvents: [PlaybackStatisticsEvent]
    public let dailyEvents: [PlaybackStatisticsBucket]
    public let kindBreakdown: [PlaybackStatisticsKindSlice]
    public let rhythm: [PlaybackStatisticsRhythmCell]
}
