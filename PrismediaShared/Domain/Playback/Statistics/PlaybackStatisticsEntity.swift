import Foundation

public struct PlaybackStatisticsEntity: Decodable, Equatable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let title: String
    public let coverURL: String?
    public let accessedCount: Int
    public let completedCount: Int
    public let skippedCount: Int
    public let activeSeconds: Double
    public let firstEventAt: Date
    public let lastEventAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, kind, title, accessedCount, completedCount, skippedCount, activeSeconds, firstEventAt, lastEventAt
        case coverURL = "coverUrl"
    }
}
