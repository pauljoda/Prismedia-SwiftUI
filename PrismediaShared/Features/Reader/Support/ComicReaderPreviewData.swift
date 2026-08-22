import SwiftUI

#if DEBUG
    enum ComicReaderPreviewData {
        static let installmentID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        static let sourcePage = EntityReaderManifestPage(
            ordinal: 0,
            mimeType: "image/png",
            width: 1_200,
            height: 1_800,
            pageType: .frontCover
        )
        static let page = BookReaderPage(entityID: installmentID, page: sourcePage)
        static let installment = EntityDetail(
            id: installmentID,
            kind: .comicInstallment,
            title: "Signal in the Static · Chapter One",
            parentEntityID: nil,
            sortOrder: 0,
            hasSourceMedia: true,
            capabilities: [
                .pageSequence(.init(
                    pageCount: 1,
                    direction: .leftToRight,
                    defaultMode: .paged,
                    coverOrdinal: 0
                ))
            ],
            childrenByKind: [],
            relationships: []
        )
        static let manifest = BookReaderManifest(
            bookID: installmentID,
            title: installment.title,
            chapters: [
                BookReaderChapter(
                    detail: installment,
                    readerPages: [page],
                    sequenceIndex: 0
                )
            ],
            nextChapter: nil,
            progress: nil,
            initialIndex: 0,
            readerMode: .paged
        )
        static let service = ComicReaderPreviewService(values: [installmentID: installment])

        @MainActor
        static var pageCache: BookReaderPageCache {
            BookReaderPageCache(service: service)
        }
    }
#endif
