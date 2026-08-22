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
            hasSourceMedia: false,
            capabilities: [
                .bookMetadata(.init(bookType: "book", format: .epub)),
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

}

private struct UnusedChapterReader: BookReaderServicing {
    func loadEntity(id: UUID) async throws -> EntityDetail {
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
