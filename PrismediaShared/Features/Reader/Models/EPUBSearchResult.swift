import Foundation

public struct EPUBSearchResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let before: String?
    public let highlight: String?
    public let after: String?
    public let chapterPage: Int?
    public let chapterPageCount: Int?
    public let location: String

    public var excerpt: String {
        (before ?? "") + (highlight ?? "") + (after ?? "")
    }

    public var locationLabel: String? {
        guard let chapterPage, let chapterPageCount else { return nil }
        return "Page \(chapterPage) of \(chapterPageCount)"
    }

    public init(
        id: String,
        title: String,
        before: String?,
        highlight: String?,
        after: String?,
        chapterPage: Int?,
        chapterPageCount: Int?,
        location: String
    ) {
        self.id = id
        self.title = title
        self.before = before
        self.highlight = highlight
        self.after = after
        self.chapterPage = chapterPage
        self.chapterPageCount = chapterPageCount
        self.location = location
    }

    public init(id: String, title: String, excerpt: String, location: String) {
        self.init(
            id: id,
            title: title,
            before: nil,
            highlight: excerpt,
            after: nil,
            chapterPage: nil,
            chapterPageCount: nil,
            location: location
        )
    }
}
