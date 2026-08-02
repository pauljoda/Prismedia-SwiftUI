import Foundation

public struct PlaybackStatisticsRhythmCell: Decodable, Equatable, Sendable, Identifiable {
    public let dayOfWeek: Int
    public let hour: Int
    public let accessedCount: Int
    public let completedCount: Int
    public let skippedCount: Int

    public var id: String { "\(dayOfWeek)-\(hour)" }
    public var totalEvents: Int { accessedCount + completedCount + skippedCount }
}
