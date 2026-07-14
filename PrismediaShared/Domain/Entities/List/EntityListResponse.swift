import Foundation

public struct EntityListResponse: Decodable, Equatable, Sendable {
    public let items: [EntityThumbnail]
    public let nextCursor: String?
    public let totalCount: Int

    public init(items: [EntityThumbnail], nextCursor: String? = nil, totalCount: Int? = nil) {
        self.items = items
        self.nextCursor = nextCursor
        self.totalCount = totalCount ?? items.count
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case nextCursor
        case totalCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let items = try container.decode([EntityThumbnail].self, forKey: .items)
        self.init(
            items: items,
            nextCursor: try container.decodeIfPresent(String.self, forKey: .nextCursor),
            // The server types totalCount as a long that may serialize as a string.
            totalCount: try container.decodeFlexibleIntIfPresent(forKey: .totalCount)
        )
    }
}
