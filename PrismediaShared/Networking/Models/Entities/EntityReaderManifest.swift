import Foundation

/// Entity-agnostic ordered image-page manifest returned by the reader API.
public struct EntityReaderManifest: Decodable, Hashable, Sendable {
    public let entityID: UUID
    public let direction: PageReadingDirection
    public let defaultMode: ReaderMode
    public let coverOrdinal: Int?
    public let pages: [EntityReaderManifestPage]

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case direction
        case defaultMode
        case coverOrdinal
        case pages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entityID = try container.decode(UUID.self, forKey: .entityID)
        direction = try container.decode(PageReadingDirection.self, forKey: .direction)
        defaultMode = try container.decode(ReaderMode.self, forKey: .defaultMode)
        coverOrdinal = try container.decodeFlexibleIntIfPresent(forKey: .coverOrdinal)
        pages = try container.decode([EntityReaderManifestPage].self, forKey: .pages)
    }
}
