import Foundation

public struct BookReaderChapter: Identifiable, Hashable, Sendable {
    public let detail: EntityDetail
    public let pages: [EntityThumbnail]
    public let sequenceIndex: Int

    public var id: UUID { detail.id }
    public var title: String { detail.title }
    public var summary: BookChapterSummary {
        .init(id: id, title: title, sortOrder: sequenceIndex, pageCount: pages.count)
    }
}
