import Foundation

/// Reader behavior and page count for an Entity backed by a generic page manifest.
public struct EntityPageSequenceCapability: Decodable, Hashable, Sendable {
    public let pageCount: Int
    public let direction: PageReadingDirection
    public let defaultMode: ReaderMode
    public let coverOrdinal: Int?

    public init(
        pageCount: Int,
        direction: PageReadingDirection,
        defaultMode: ReaderMode,
        coverOrdinal: Int?
    ) {
        self.pageCount = pageCount
        self.direction = direction
        self.defaultMode = defaultMode
        self.coverOrdinal = coverOrdinal
    }

    private enum CodingKeys: String, CodingKey {
        case pageCount
        case direction
        case defaultMode
        case coverOrdinal
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageCount = try container.decodeFlexibleInt(forKey: .pageCount)
        direction = try container.decode(PageReadingDirection.self, forKey: .direction)
        defaultMode = try container.decode(ReaderMode.self, forKey: .defaultMode)
        coverOrdinal = try container.decodeFlexibleIntIfPresent(forKey: .coverOrdinal)
    }
}
