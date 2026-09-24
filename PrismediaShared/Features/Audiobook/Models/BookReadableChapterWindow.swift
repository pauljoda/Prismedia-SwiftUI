import Foundation

/// The readable side of one server alignment row: an EPUB table-of-contents chapter with its
/// whole-book fraction window, or a paged chapter Entity with its page count.
public struct BookReadableChapterWindow: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Stable readable chapter key used by chapter mappings.
    public let chapterKey: String
    public let title: String
    public let depth: Int
    /// EPUB resource location that opens the chapter, when the chapter is part of an EPUB.
    public let location: String?
    /// Chapter Entity that holds the chapter's pages, for paged Books.
    public let chapterEntityID: UUID?
    public let startFraction: Double?
    public let endFraction: Double?
    public let pageCount: Int?

    // MARK: - Initializers

    public init(
        chapterKey: String,
        title: String,
        depth: Int = 0,
        location: String? = nil,
        chapterEntityID: UUID? = nil,
        startFraction: Double? = nil,
        endFraction: Double? = nil,
        pageCount: Int? = nil
    ) {
        self.chapterKey = chapterKey
        self.title = title
        self.depth = depth
        self.location = location
        self.chapterEntityID = chapterEntityID
        self.startFraction = startFraction
        self.endFraction = endFraction
        self.pageCount = pageCount
    }
}

extension BookReadableChapterWindow: Decodable {
    private enum CodingKeys: String, CodingKey {
        case chapterKey, title, depth, location
        case chapterEntityID = "chapterEntityId"
        case startFraction, endFraction, pageCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterKey = try container.decode(String.self, forKey: .chapterKey)
        title = try container.decode(String.self, forKey: .title)
        depth = try container.decodeFlexibleIntIfPresent(forKey: .depth) ?? 0
        location = try container.decodeIfPresent(String.self, forKey: .location)
        chapterEntityID = try container.decodeIfPresent(UUID.self, forKey: .chapterEntityID)
        startFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .startFraction)
        endFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .endFraction)
        pageCount = try container.decodeFlexibleIntIfPresent(forKey: .pageCount)
    }
}
