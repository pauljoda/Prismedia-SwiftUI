import Foundation

public struct BookReaderManifest: Hashable, Sendable {
    public let bookID: UUID
    public let title: String
    public let chapters: [BookReaderChapter]
    public let tableOfContents: [BookChapterSummary]
    public let nextChapter: BookChapterSummary?
    public let progress: EntityProgressCapability?
    public let initialIndex: Int
    public let readerMode: ReaderMode
    public let readingDirection: PageReadingDirection
    public let coverOrdinal: Int?
    public let completesAtManifestEnd: Bool

    public var pages: [BookReaderPage] { chapters.flatMap(\.pages) }

    public init(
        bookID: UUID,
        title: String,
        chapters: [BookReaderChapter],
        tableOfContents: [BookChapterSummary] = [],
        nextChapter: BookChapterSummary?,
        progress: EntityProgressCapability?,
        initialIndex: Int,
        readerMode: ReaderMode,
        readingDirection: PageReadingDirection = .leftToRight,
        coverOrdinal: Int? = 0,
        completesAtManifestEnd: Bool? = nil
    ) {
        self.bookID = bookID
        self.title = title
        self.chapters = chapters
        self.tableOfContents = tableOfContents.isEmpty ? chapters.map(\.summary) : tableOfContents
        self.nextChapter = nextChapter
        self.progress = progress
        self.initialIndex = initialIndex
        self.readerMode = readerMode
        self.readingDirection = readingDirection
        self.coverOrdinal = coverOrdinal
        self.completesAtManifestEnd = completesAtManifestEnd ?? (nextChapter == nil)
    }

    public func position(at index: Int) -> BookReaderPosition? {
        guard !pages.isEmpty else { return nil }
        let target = max(0, min(index, pages.count - 1))
        var offset = 0
        for chapter in chapters {
            let nextOffset = offset + chapter.pages.count
            if target < nextOffset {
                return .init(
                    chapterID: chapter.id,
                    pageIndex: target - offset,
                    pageCount: chapter.pages.count
                )
            }
            offset = nextOffset
        }
        return nil
    }
}
