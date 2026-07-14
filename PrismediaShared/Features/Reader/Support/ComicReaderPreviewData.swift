import SwiftUI

#if DEBUG
    enum ComicReaderPreviewData {
        static let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        static let chapterID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        static let pageID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        static let chapterThumbnail = EntityThumbnail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter One",
            parentEntityID: bookID,
            sortOrder: 0
        )
        static let pageThumbnail = EntityThumbnail(
            id: pageID,
            kind: .bookPage,
            title: "Page One",
            parentEntityID: chapterID,
            sortOrder: 0
        )
        static let book = EntityDetail(
            id: bookID,
            kind: .book,
            title: "Signal in the Static",
            parentEntityID: nil,
            sortOrder: nil,
            bookType: "comic",
            bookFormat: .imageArchive,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [.init(kind: .bookChapter, label: "Chapters", entities: [chapterThumbnail], code: nil)],
            relationships: []
        )
        static let chapter = EntityDetail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter One",
            parentEntityID: bookID,
            sortOrder: 0,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [.init(kind: .bookPage, label: "Pages", entities: [pageThumbnail], code: nil)],
            relationships: []
        )
        static let manifest = BookReaderManifest(
            bookID: bookID,
            title: book.title,
            chapters: [
                BookReaderChapter(
                    detail: chapter,
                    pages: [pageThumbnail],
                    sequenceIndex: 0
                )
            ],
            nextChapter: BookChapterSummary(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                title: "Chapter Two",
                sortOrder: 1,
                pageCount: 18
            ),
            progress: nil,
            initialIndex: 0,
            readerMode: .paged
        )
        static let service = ComicReaderPreviewService(values: [bookID: book, chapterID: chapter])

        @MainActor
        static var pageCache: BookReaderPageCache {
            BookReaderPageCache(service: service)
        }
    }

#endif
