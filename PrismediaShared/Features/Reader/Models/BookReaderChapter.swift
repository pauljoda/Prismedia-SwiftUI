import Foundation

public struct BookReaderChapter: Identifiable, Hashable, Sendable {
    public let detail: EntityDetail
    public let pages: [BookReaderPage]
    public let sequenceIndex: Int

    public var id: UUID { detail.id }
    public var title: String { detail.title }
    public var summary: BookChapterSummary {
        .init(id: id, title: title, sortOrder: sequenceIndex, pageCount: pages.count)
    }

    public init(
        detail: EntityDetail,
        pages: [EntityThumbnail],
        sequenceIndex: Int
    ) {
        self.detail = detail
        self.pages = pages.map(BookReaderPage.init(thumbnail:))
        self.sequenceIndex = sequenceIndex
    }

    public init(
        detail: EntityDetail,
        readerPages: [BookReaderPage],
        sequenceIndex: Int
    ) {
        self.detail = detail
        pages = readerPages
        self.sequenceIndex = sequenceIndex
    }
}
