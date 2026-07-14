import Foundation

public struct EPUBBookmarksState: Codable, Hashable, Sendable {
    public var bookmarks: [EPUBBookmark]
    public var toggleBookmarkID: UUID?

    public init(
        bookmarks: [EPUBBookmark] = [],
        toggleBookmarkID: UUID? = nil
    ) {
        self.bookmarks = bookmarks
        self.toggleBookmarkID =
            bookmarks.contains { $0.id == toggleBookmarkID }
            ? toggleBookmarkID
            : nil
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            bookmarks: try container.decode([EPUBBookmark].self, forKey: .bookmarks),
            toggleBookmarkID: try container.decodeIfPresent(UUID.self, forKey: .toggleBookmarkID)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case bookmarks
        case toggleBookmarkID
    }
}
