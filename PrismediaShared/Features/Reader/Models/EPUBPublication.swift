import Foundation

public struct EPUBPublication: Equatable, Sendable {
    public let title: String
    public let chapters: [EPUBChapter]
    public let tableOfContents: [EPUBTableOfContentsItem]
    public let rootURL: URL

    public init(
        title: String,
        chapters: [EPUBChapter],
        tableOfContents: [EPUBTableOfContentsItem] = [],
        rootURL: URL
    ) {
        self.title = title
        self.chapters = chapters
        self.tableOfContents = tableOfContents
        self.rootURL = rootURL
    }
}
