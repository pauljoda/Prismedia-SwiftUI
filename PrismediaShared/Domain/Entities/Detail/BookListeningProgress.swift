import Foundation

/// Exact physical audiobook position retained while the Book's latest activity is reading.
public struct BookListeningProgress: Decodable, Hashable, Sendable {
    public let trackEntityID: UUID
    public let markerID: UUID?
    public let offsetSeconds: Double
    public let currentEntityID: UUID
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case trackEntityID = "trackEntityId"
        case markerID = "markerId"
        case offsetSeconds
        case currentEntityID = "currentEntityId"
        case unit, index, total, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackEntityID = try container.decode(UUID.self, forKey: .trackEntityID)
        markerID = try container.decodeIfPresent(UUID.self, forKey: .markerID)
        offsetSeconds = try container.decodeFlexibleDouble(forKey: .offsetSeconds)
        currentEntityID = try container.decode(UUID.self, forKey: .currentEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
