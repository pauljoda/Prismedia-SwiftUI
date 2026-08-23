import XCTest

@testable import PrismediaCore

final class BookChapterContentsLoadPolicyTests: XCTestCase {
    func testCompleteEPUBWithSourceCanLoadChapters() {
        let book = makeBook(hasSourceMedia: true, isWanted: false)

        XCTAssertTrue(BookChapterContentsLoadPolicy.canLoad(book))
    }

    func testWantedOnlyEPUBCannotLoadChapters() {
        let book = makeBook(hasSourceMedia: false, isWanted: true)

        XCTAssertFalse(BookChapterContentsLoadPolicy.canLoad(book))
    }

    func testFilelessEPUBCanLoadTheServerProjection() {
        let book = makeBook(hasSourceMedia: false, isWanted: false)

        XCTAssertTrue(BookChapterContentsLoadPolicy.canLoad(book))
    }

    func testPDFCanLoadChapterEntitySummaries() {
        let book = EntityDetail(
            id: UUID(),
            kind: .book,
            title: "PDF Book",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [.bookMetadata(.init(bookType: "book", format: .pdf))],
            childrenByKind: [],
            relationships: []
        )

        XCTAssertTrue(BookChapterContentsLoadPolicy.canLoad(book))
    }

    private func makeBook(
        hasSourceMedia: Bool,
        isWanted: Bool
    ) -> EntityDetail {
        EntityDetail(
            id: UUID(),
            kind: .book,
            title: "Book",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: hasSourceMedia,
            capabilities: [
                .bookMetadata(.init(bookType: "book", format: .epub)),
                .flags(
                    EntityFlagsCapability(
                        isFavorite: false,
                        isNsfw: false,
                        isOrganized: false,
                        isWanted: isWanted
                    )
                ),
            ],
            childrenByKind: [],
            relationships: []
        )
    }
}
