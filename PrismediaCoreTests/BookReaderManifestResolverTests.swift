import XCTest

@testable import PrismediaCore

final class BookReaderManifestResolverTests: XCTestCase {
    func testRootBookResumeReloadsFreshProgressBeforeSelectingPage() async throws {
        let bookID = UUID(uuidString: "01000000-0000-0000-0000-000000000000")!
        let chapterID = UUID(uuidString: "02000000-0000-0000-0000-000000000000")!
        let firstPageID = UUID(uuidString: "03000000-0000-0000-0000-000000000000")!
        let secondPageID = UUID(uuidString: "04000000-0000-0000-0000-000000000000")!
        let chapterThumbnail = thumbnail(
            chapterID,
            .bookChapter,
            "Chapter",
            order: 0,
            parent: bookID
        )
        let staleBook = detail(
            id: bookID,
            kind: .book,
            title: "Book",
            children: [group(.bookChapter, [chapterThumbnail])]
        )
        let freshBook = detail(
            id: bookID,
            kind: .book,
            title: "Book",
            progress: .init(
                currentEntityID: chapterID,
                unit: .page,
                index: 1,
                total: 2,
                mode: .webtoon,
                completedAt: nil,
                updatedAt: nil,
                workIndex: 1,
                workTotal: 2,
                location: nil
            ),
            children: [group(.bookChapter, [chapterThumbnail])]
        )
        let chapter = detail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter",
            parent: bookID,
            children: [
                group(
                    .bookPage,
                    [
                        thumbnail(firstPageID, .bookPage, "Page 1", order: 0, parent: chapterID),
                        thumbnail(secondPageID, .bookPage, "Page 2", order: 1, parent: chapterID),
                    ]
                )
            ]
        )
        let loader = ManifestEntityLoader(values: [bookID: freshBook, chapterID: chapter])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: staleBook,
            command: .resume
        )

        XCTAssertEqual(manifest.initialIndex, 1)
        XCTAssertEqual(manifest.readerMode, .webtoon)
        XCTAssertEqual(manifest.pages.map(\.id), [firstPageID, secondPageID])
    }

    func testBookResumeLoadsSavedChapterInsideVolumeAndFindsNextVolumeChapter() async throws {
        let bookID = UUID(uuidString: "10000000-0000-0000-0000-000000000000")!
        let volumeOneID = UUID(uuidString: "20000000-0000-0000-0000-000000000000")!
        let volumeTwoID = UUID(uuidString: "30000000-0000-0000-0000-000000000000")!
        let chapterOneID = UUID(uuidString: "40000000-0000-0000-0000-000000000000")!
        let chapterTwoID = UUID(uuidString: "50000000-0000-0000-0000-000000000000")!
        let pageOneID = UUID(uuidString: "60000000-0000-0000-0000-000000000000")!
        let pageTwoID = UUID(uuidString: "70000000-0000-0000-0000-000000000000")!

        let book = detail(
            id: bookID,
            kind: .book,
            title: "Saga",
            progress: .init(
                currentEntityID: chapterOneID,
                unit: .page,
                index: 0,
                total: 1,
                mode: .webtoon,
                completedAt: nil,
                updatedAt: nil,
                workIndex: 0,
                workTotal: 2,
                location: nil
            ),
            children: [
                group(
                    .bookVolume,
                    [
                        thumbnail(volumeTwoID, .bookVolume, "Volume 2", order: 2, parent: bookID),
                        thumbnail(volumeOneID, .bookVolume, "Volume 1", order: 1, parent: bookID),
                    ])
            ]
        )
        let volumeOne = detail(
            id: volumeOneID,
            kind: .bookVolume,
            title: "Volume 1",
            parent: bookID,
            children: [
                group(.bookChapter, [thumbnail(chapterOneID, .bookChapter, "Chapter 1", order: 0, parent: volumeOneID)])
            ]
        )
        let volumeTwo = detail(
            id: volumeTwoID,
            kind: .bookVolume,
            title: "Volume 2",
            parent: bookID,
            children: [
                group(.bookChapter, [thumbnail(chapterTwoID, .bookChapter, "Chapter 2", order: 0, parent: volumeTwoID)])
            ]
        )
        let chapterOne = detail(
            id: chapterOneID,
            kind: .bookChapter,
            title: "Chapter 1",
            parent: volumeOneID,
            children: [group(.bookPage, [thumbnail(pageOneID, .bookPage, "Page 1", order: 0, parent: chapterOneID)])]
        )
        let chapterTwo = detail(
            id: chapterTwoID,
            kind: .bookChapter,
            title: "Chapter 2",
            parent: volumeTwoID,
            children: [group(.bookPage, [thumbnail(pageTwoID, .bookPage, "Page 2", order: 0, parent: chapterTwoID)])]
        )
        let loader = ManifestEntityLoader(values: [
            bookID: book,
            volumeOneID: volumeOne,
            volumeTwoID: volumeTwo,
            chapterOneID: chapterOne,
            chapterTwoID: chapterTwo,
        ])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: book,
            command: .resume
        )

        XCTAssertEqual(manifest.bookID, bookID)
        XCTAssertEqual(manifest.chapters.map(\.id), [chapterOneID])
        XCTAssertEqual(manifest.pages.map(\.id), [pageOneID])
        XCTAssertEqual(manifest.initialIndex, 0)
        XCTAssertEqual(manifest.readerMode, .webtoon)
        XCTAssertEqual(manifest.nextChapter?.id, chapterTwoID)
    }

    func testVolumeReaderFlattensOrderedChapterPagesAndMapsProgressToLocalPosition() async throws {
        let bookID = UUID(uuidString: "11000000-0000-0000-0000-000000000000")!
        let volumeID = UUID(uuidString: "22000000-0000-0000-0000-000000000000")!
        let firstChapterID = UUID(uuidString: "33000000-0000-0000-0000-000000000000")!
        let secondChapterID = UUID(uuidString: "44000000-0000-0000-0000-000000000000")!
        let firstPageID = UUID(uuidString: "55000000-0000-0000-0000-000000000000")!
        let secondPageID = UUID(uuidString: "66000000-0000-0000-0000-000000000000")!
        let book = detail(
            id: bookID,
            kind: .book,
            title: "Book",
            progress: .init(
                currentEntityID: secondChapterID, unit: .page, index: 0, total: 1, mode: .paged, completedAt: nil,
                updatedAt: nil, workIndex: 1, workTotal: 2, location: nil),
            children: [group(.bookVolume, [thumbnail(volumeID, .bookVolume, "Volume", order: 0, parent: bookID)])]
        )
        let volume = detail(
            id: volumeID,
            kind: .bookVolume,
            title: "Volume",
            parent: bookID,
            children: [
                group(
                    .bookChapter,
                    [
                        thumbnail(secondChapterID, .bookChapter, "Second", order: 2, parent: volumeID),
                        thumbnail(firstChapterID, .bookChapter, "First", order: 1, parent: volumeID),
                    ])
            ]
        )
        let first = detail(
            id: firstChapterID, kind: .bookChapter, title: "First", parent: volumeID,
            children: [
                group(.bookPage, [thumbnail(firstPageID, .bookPage, "First page", order: 0, parent: firstChapterID)])
            ])
        let second = detail(
            id: secondChapterID, kind: .bookChapter, title: "Second", parent: volumeID,
            children: [
                group(.bookPage, [thumbnail(secondPageID, .bookPage, "Second page", order: 0, parent: secondChapterID)])
            ])
        let loader = ManifestEntityLoader(values: [
            bookID: book, volumeID: volume, firstChapterID: first, secondChapterID: second,
        ])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(selected: volume, command: .resume)

        XCTAssertEqual(manifest.chapters.map(\.id), [firstChapterID, secondChapterID])
        XCTAssertEqual(manifest.pages.map(\.id), [firstPageID, secondPageID])
        XCTAssertEqual(manifest.initialIndex, 1)
        XCTAssertNil(manifest.nextChapter)
        XCTAssertEqual(manifest.position(at: 1)?.chapterID, secondChapterID)
        XCTAssertEqual(manifest.position(at: 1)?.pageIndex, 0)
    }

    func testNonFinalVolumeContinuesIntoTheNextVolumesFirstChapter() async throws {
        let bookID = UUID(uuidString: "12000000-0000-0000-0000-000000000000")!
        let firstVolumeID = UUID(uuidString: "23000000-0000-0000-0000-000000000000")!
        let secondVolumeID = UUID(uuidString: "34000000-0000-0000-0000-000000000000")!
        let firstChapterID = UUID(uuidString: "45000000-0000-0000-0000-000000000000")!
        let secondChapterID = UUID(uuidString: "56000000-0000-0000-0000-000000000000")!
        let firstPageID = UUID(uuidString: "67000000-0000-0000-0000-000000000000")!
        let secondPageID = UUID(uuidString: "78000000-0000-0000-0000-000000000000")!
        let book = detail(
            id: bookID,
            kind: .book,
            title: "Book",
            children: [
                group(
                    .bookVolume,
                    [
                        thumbnail(firstVolumeID, .bookVolume, "Volume 1", order: 0, parent: bookID),
                        thumbnail(secondVolumeID, .bookVolume, "Volume 2", order: 1, parent: bookID),
                    ]
                )
            ]
        )
        let firstVolume = detail(
            id: firstVolumeID,
            kind: .bookVolume,
            title: "Volume 1",
            parent: bookID,
            children: [
                group(
                    .bookChapter,
                    [thumbnail(firstChapterID, .bookChapter, "Chapter 1", order: 0, parent: firstVolumeID)]
                )
            ]
        )
        let secondVolume = detail(
            id: secondVolumeID,
            kind: .bookVolume,
            title: "Volume 2",
            parent: bookID,
            children: [
                group(
                    .bookChapter,
                    [thumbnail(secondChapterID, .bookChapter, "Chapter 2", order: 0, parent: secondVolumeID)]
                )
            ]
        )
        let firstChapter = detail(
            id: firstChapterID,
            kind: .bookChapter,
            title: "Chapter 1",
            parent: firstVolumeID,
            children: [
                group(.bookPage, [thumbnail(firstPageID, .bookPage, "Page 1", order: 0, parent: firstChapterID)])
            ]
        )
        let secondChapter = detail(
            id: secondChapterID,
            kind: .bookChapter,
            title: "Chapter 2",
            parent: secondVolumeID,
            children: [
                group(.bookPage, [thumbnail(secondPageID, .bookPage, "Page 2", order: 0, parent: secondChapterID)])
            ]
        )
        let loader = ManifestEntityLoader(values: [
            bookID: book,
            firstVolumeID: firstVolume,
            secondVolumeID: secondVolume,
            firstChapterID: firstChapter,
            secondChapterID: secondChapter,
        ])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: firstVolume,
            command: .read
        )

        XCTAssertEqual(manifest.pages.map(\.id), [firstPageID])
        XCTAssertEqual(manifest.nextChapter?.id, secondChapterID)
        XCTAssertEqual(manifest.nextChapter?.title, "Chapter 2")
    }

    private func detail(
        id: UUID,
        kind: EntityKind,
        title: String,
        parent: UUID? = nil,
        progress: EntityProgressCapability? = nil,
        children: [EntityGroup] = []
    ) -> EntityDetail {
        EntityDetail(
            id: id,
            kind: kind,
            title: title,
            parentEntityID: parent,
            sortOrder: nil,
            bookFormat: kind == .book ? .imageArchive : nil,
            hasSourceMedia: false,
            capabilities: progress.map { [.progress($0)] } ?? [],
            childrenByKind: children,
            relationships: []
        )
    }

    private func group(_ kind: EntityKind, _ entities: [EntityThumbnail]) -> EntityGroup {
        EntityGroup(kind: kind, label: kind.displayLabel, entities: entities, code: nil)
    }

    private func thumbnail(_ id: UUID, _ kind: EntityKind, _ title: String, order: Int, parent: UUID) -> EntityThumbnail
    {
        EntityThumbnail(id: id, kind: kind, title: title, parentEntityID: parent, sortOrder: order)
    }
}

private struct ManifestEntityLoader: EntityDetailLoading {
    let values: [UUID: EntityDetail]

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let value = values[id] else { throw ManifestLoaderError.missing(id) }
        return value
    }
}

private enum ManifestLoaderError: Error {
    case missing(UUID)
}
