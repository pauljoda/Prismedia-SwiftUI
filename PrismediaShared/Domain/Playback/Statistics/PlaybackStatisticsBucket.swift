import Foundation

public struct PlaybackStatisticsBucket: Decodable, Equatable, Sendable, Identifiable {
    public let date: String
    public let accessedCount: Int
    public let completedCount: Int
    public let skippedCount: Int
    public let activeSeconds: Double
    public let viewingSeconds: Double
    public let listeningSeconds: Double
    public let readingSeconds: Double

    public var id: String { date }
    public var totalCount: Int { accessedCount + completedCount + skippedCount }
}
