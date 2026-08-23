import XCTest

@testable import PrismediaCore

final class BookContentsServiceTests: XCTestCase {
    func testMapsServerProjectedEPUBContentsAndMatchesTheSavedLocation() async throws {
        let loader = BookContentsLoaderStub(entries: [
            BookContentsEntry(
                id: "Text/chapter-1.xhtml",
                title: "Chapter One",
                location: "Text/chapter-1.xhtml",
                depth: 0,
                order: 0,
                sectionIndex: 0,
                startFraction: 0,
                endFraction: 0.5,
                pageCount: nil
            ),
            BookContentsEntry(
                id: "Text/chapter-2.xhtml",
                title: "Chapter Two",
                location: "Text/chapter-2.xhtml",
                depth: 0,
                order: 1,
                sectionIndex: 1,
                startFraction: 0.5,
                endFraction: 1,
                pageCount: nil
            ),
        ])
        let book = makeBook(
            format: .epub,
            progress: EntityProgressCapability(
                currentEntityID: UUID(),
                unit: .cfi,
                index: 6_000,
                total: 10_000,
                mode: .paged,
                completedAt: nil,
                updatedAt: nil,
                workIndex: 6_000,
                workTotal: 10_000,
                location: #"{"href":"/OEBPS/Text/chapter-2.xhtml","locations":{"progression":0.2}}"#
            )
        )

        let contents = try await BookContentsService(loader: loader).load(book: book)
        let requestedBookIDs = await loader.requestedBookIDs()

        XCTAssertEqual(contents.chapters.map(\.title), ["Chapter One", "Chapter Two"])
        XCTAssertEqual(contents.chapters.last?.target, .epub(location: "Text/chapter-2.xhtml"))
        XCTAssertEqual(contents.currentChapterID, "Text/chapter-2.xhtml")
        XCTAssertEqual(
            contents.progressRanges.map(\.location),
            [
                "Text/chapter-1.xhtml",
                "Text/chapter-2.xhtml",
            ])
        XCTAssertEqual(requestedBookIDs, [book.id])
    }

    func testMapsChapterEntityContentsAndTheirCachedPageCounts() async throws {
        let chapterID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = BookContentsLoaderStub(entries: [
            BookContentsEntry(
                id: chapterID.uuidString.lowercased(),
                title: "Part One",
                location: chapterID.uuidString.lowercased(),
                depth: 0,
                order: 0,
                sectionIndex: nil,
                startFraction: nil,
                endFraction: nil,
                pageCount: 42
            )
        ])
        let book = makeBook(
            format: .pdf,
            progress: EntityProgressCapability(
                currentEntityID: chapterID,
                unit: .page,
                index: 12,
                total: 42,
                mode: .paged,
                completedAt: nil,
                updatedAt: nil,
                workIndex: nil,
                workTotal: nil,
                location: nil
            )
        )

        let contents = try await BookContentsService(loader: loader).load(book: book)

        XCTAssertEqual(contents.chapters.first?.target, .entityChapter(id: chapterID))
        XCTAssertEqual(contents.chapters.first?.pageCount, 42)
        XCTAssertEqual(contents.currentChapterID, chapterID.uuidString.lowercased())
    }

    func testWantedOnlyBookReturnsEmptyContentsWithoutLoadingTheProjection() async throws {
        let loader = BookContentsLoaderStub(entries: [])
        let book = makeBook(format: .epub, isWanted: true)

        let contents = try await BookContentsService(loader: loader).load(book: book)
        let requestedBookIDs = await loader.requestedBookIDs()

        XCTAssertTrue(contents.chapters.isEmpty)
        XCTAssertTrue(requestedBookIDs.isEmpty)
    }

    private func makeBook(
        format: BookFormat,
        isWanted: Bool = false,
        progress: EntityProgressCapability? = nil
    ) -> EntityDetail {
        var capabilities: [EntityCapability] = [
            .bookMetadata(.init(bookType: "book", format: format)),
            .flags(
                EntityFlagsCapability(
                    isFavorite: false,
                    isNsfw: false,
                    isOrganized: false,
                    isWanted: isWanted
                )
            ),
        ]
        if let progress {
            capabilities.append(.progress(progress))
        }
        return EntityDetail(
            id: UUID(),
            kind: .book,
            title: "Book",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: !isWanted,
            capabilities: capabilities,
            childrenByKind: [],
            relationships: []
        )
    }
}

private actor BookContentsLoaderStub: BookContentsLoading {
    private let entries: [BookContentsEntry]
    private var requests: [UUID] = []

    init(entries: [BookContentsEntry]) {
        self.entries = entries
    }

    func loadBookContents(bookID: UUID) async throws -> [BookContentsEntry] {
        requests.append(bookID)
        return entries
    }

    func requestedBookIDs() -> [UUID] {
        requests
    }
}
