import Foundation

/// Exact reading cursor retained while the Book's latest activity is listening.
public struct BookReadingProgress: Decodable, Hashable, Sendable {
    public let currentEntityID: UUID
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    public let mode: ReaderMode?
    public let location: String?
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case currentEntityID = "currentEntityId"
        case unit, index, total, mode, location, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentEntityID = try container.decode(UUID.self, forKey: .currentEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
