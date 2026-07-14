import Foundation

public struct EPUBBookmark: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let locator: String
    public let chapterTitle: String
    public let chapterPage: Int
    public let chapterPageCount: Int
    public let createdAt: Date

    public init(
        id: UUID,
        locator: String,
        chapterTitle: String,
        chapterPage: Int,
        chapterPageCount: Int,
        createdAt: Date
    ) {
        let chapterPageCount = max(1, chapterPageCount)
        self.id = id
        self.locator = locator
        self.chapterTitle = chapterTitle
        self.chapterPage = min(max(1, chapterPage), chapterPageCount)
        self.chapterPageCount = chapterPageCount
        self.createdAt = createdAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            locator: try container.decode(String.self, forKey: .locator),
            chapterTitle: try container.decode(String.self, forKey: .chapterTitle),
            chapterPage: try container.decode(Int.self, forKey: .chapterPage),
            chapterPageCount: try container.decode(Int.self, forKey: .chapterPageCount),
            createdAt: try container.decode(Date.self, forKey: .createdAt)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case locator
        case chapterTitle
        case chapterPage
        case chapterPageCount
        case createdAt
    }
}
