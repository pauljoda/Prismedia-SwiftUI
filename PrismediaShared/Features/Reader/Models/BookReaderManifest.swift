import Foundation

public struct BookReaderManifest: Hashable, Sendable {
    public let bookID: UUID
    public let title: String
    public let chapters: [BookReaderChapter]
    public let nextChapter: BookChapterSummary?
    public let progress: EntityProgressCapability?
    public let initialIndex: Int
    public let readerMode: ReaderMode

    public var pages: [EntityThumbnail] { chapters.flatMap(\.pages) }

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
