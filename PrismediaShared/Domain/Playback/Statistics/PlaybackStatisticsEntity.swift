import Foundation

public struct PlaybackStatisticsEntity: Decodable, Equatable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let title: String
    public let coverURL: String?
    public let completedCount: Int
    public let skippedCount: Int
    public let lastEventAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, kind, title, completedCount, skippedCount, lastEventAt
        case coverURL = "coverUrl"
    }
}
