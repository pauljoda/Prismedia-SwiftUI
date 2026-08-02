import Foundation

public struct ConsumptionStatisticsResponse: Decodable, Equatable, Sendable {
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
    public let topEntities: [ConsumptionStatisticsEntity]
    public let recentEvents: [ConsumptionStatisticsEvent]
    public let dailyEvents: [ConsumptionStatisticsBucket]
    public let kindBreakdown: [ConsumptionStatisticsKindSlice]
    public let rhythm: [ConsumptionStatisticsRhythmCell]
}
