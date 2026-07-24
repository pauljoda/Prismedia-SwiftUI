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
