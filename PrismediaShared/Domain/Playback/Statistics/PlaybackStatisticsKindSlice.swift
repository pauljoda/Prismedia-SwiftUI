import Foundation

public struct PlaybackStatisticsKindSlice: Decodable, Equatable, Sendable, Identifiable {
    public let kind: EntityKind
    public let totalEvents: Int
    public let accessedCount: Int
    public let completedCount: Int
    public let skippedCount: Int
    public let distinctEntityCount: Int
    public let activeSeconds: Double

    public var id: String { kind.rawValue }
}
