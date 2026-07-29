import XCTest

@testable import PrismediaCore

final class EPUBChapterContentsServiceTests: XCTestCase {
    func testWantedOnlyBookReturnsEmptyContentsWithoutLoadingSource() async throws {
        let service = EPUBChapterContentsService(reader: UnusedChapterReader())
        let book = EntityDetail(
            id: UUID(),
            kind: .book,
            title: "Wanted Book",
            parentEntityID: nil,
            sortOrder: nil,
            bookFormat: .epub,
            hasSourceMedia: false,
            capabilities: [
                .flags(
                    EntityFlagsCapability(
                        isFavorite: false,
                        isNsfw: false,
                        isOrganized: false,
                        isWanted: true
                    )
                )
            ],
            childrenByKind: [],
            relationships: []
        )

        let contents = try await service.load(book: book)

        XCTAssertTrue(contents.chapters.isEmpty)
        XCTAssertNil(contents.currentChapterID)
    }

    func testCurrentReadingChapterMatchesPackagePrefixedReadiumLocation() {
        let service = EPUBChapterContentsService(reader: UnusedChapterReader())
        let chapter = ReadableBookChapter(
            id: "chapter-seven",
            title: "Chapter Seven",
            order: 6,
            depth: 0,
            target: .epub(location: "Text/chapter-7.xhtml")
        )
        let storedLocation = """
            {
              "href": "/OEBPS/Text/chapter-7.xhtml",
              "locations": { "progression": 0.42 }
            }
            """

        let currentChapterID = service.currentChapterID(
            progressLocation: storedLocation,
            chapters: [chapter]
        )

        XCTAssertEqual(currentChapterID, chapter.id)
    }

    func testSharedProgressBoundarySelectsTheLaterReadableChapter() {
        let service = EPUBChapterContentsService(reader: UnusedChapterReader())
        let chapters = [
            ReadableBookChapter(
                id: "chapter-one",
                title: "Chapter One",
                order: 0,
                depth: 0,
                target: .epub(location: "Text/chapter-1.xhtml"),
                startFraction: 0,
                endFraction: 0.5
            ),
            ReadableBookChapter(
                id: "chapter-two",
                title: "Chapter Two",
                order: 1,
                depth: 0,
                target: .epub(location: "Text/chapter-2.xhtml"),
                startFraction: 0.5,
                endFraction: 1
            ),
        ]
        let progress = EntityProgressCapability(
            currentEntityID: UUID(),
            unit: .cfi,
            index: 5_000,
            total: 10_000,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 5_000,
            workTotal: 10_000,
            location: nil
        )

        XCTAssertEqual(
            service.currentChapterID(progress: progress, chapters: chapters),
            chapters[1].id
        )
    }

    func testImageArchiveChaptersExposePageCountsAndCanonicalCurrentChapter() async throws {
        let bookID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let chapterID = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let pages = (0..<3).map { index in
            EntityThumbnail(
                id: UUID(),
                kind: .bookPage,
                title: "Page \(index + 1)",
                parentEntityID: chapterID,
                sortOrder: index
            )
        }
        let chapterThumbnail = EntityThumbnail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter One",
            parentEntityID: bookID,
            sortOrder: 0
        )
        let book = EntityDetail(
            id: bookID,
            kind: .book,
            title: "Comic",
            parentEntityID: nil,
            sortOrder: nil,
            bookFormat: .imageArchive,
            hasSourceMedia: false,
            capabilities: [
                .progress(
                    EntityProgressCapability(
                        currentEntityID: chapterID,
                        unit: .page,
                        index: 1,
                        total: 3,
                        mode: .paged,
                        completedAt: nil,
                        updatedAt: nil,
                        workIndex: 1,
                        workTotal: 3,
                        location: nil
                    )
                )
            ],
            childrenByKind: [
                EntityGroup(
                    kind: .bookChapter,
                    label: "Chapters",
                    entities: [chapterThumbnail],
                    code: nil
                )
            ],
            relationships: []
        )
        let chapter = EntityDetail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter One",
            parentEntityID: bookID,
            sortOrder: 0,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [
                EntityGroup(kind: .bookPage, label: "Pages", entities: pages, code: nil)
            ],
            relationships: []
        )
        let service = EPUBChapterContentsService(
            reader: ImageChapterReader(values: [chapterID: chapter])
        )

        let contents = try await service.load(book: book)

        XCTAssertEqual(contents.currentChapterID, chapterID.uuidString.lowercased())
        XCTAssertEqual(contents.chapters.count, 1)
        XCTAssertEqual(contents.chapters[0].target, .entityChapter(id: chapterID))
        XCTAssertEqual(contents.chapters[0].pageCount, 3)
    }
}

private struct ImageChapterReader: BookReaderServicing {
    let values: [UUID: EntityDetail]

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let value = values[id] else { throw UnusedChapterReaderError.unexpectedCall }
        return value
    }

    func loadPageData(id: UUID) async throws -> Data {
        throw UnusedChapterReaderError.unexpectedCall
    }

    func updateReadingProgress(
        id: UUID,
        request: EntityProgressUpdateRequest
    ) async throws {
        throw UnusedChapterReaderError.unexpectedCall
    }
}

private struct UnusedChapterReader: BookReaderServicing {
    func loadEntity(id: UUID) async throws -> EntityDetail {
        throw UnusedChapterReaderError.unexpectedCall
    }

    func loadPageData(id: UUID) async throws -> Data {
        throw UnusedChapterReaderError.unexpectedCall
    }

    func updateReadingProgress(
        id: UUID,
        request: EntityProgressUpdateRequest
    ) async throws {
        throw UnusedChapterReaderError.unexpectedCall
    }
}

private enum UnusedChapterReaderError: Error {
    case unexpectedCall
}
