import Foundation

public struct PlaybackStatisticsBucket: Decodable, Equatable, Sendable, Identifiable {
    public let date: String
    public let completedCount: Int
    public let skippedCount: Int

    public var id: String { date }
    public var totalCount: Int { completedCount + skippedCount }
}
