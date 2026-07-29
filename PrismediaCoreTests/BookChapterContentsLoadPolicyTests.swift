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

    func testFilelessEPUBCannotLoadChapters() {
        let book = makeBook(hasSourceMedia: false, isWanted: false)

        XCTAssertFalse(BookChapterContentsLoadPolicy.canLoad(book))
    }

    func testImageArchiveCanLoadChapterMetadataWithoutABookSourceFile() {
        let book = EntityDetail(
            id: UUID(),
            kind: .book,
            title: "Comic",
            parentEntityID: nil,
            sortOrder: nil,
            bookFormat: .imageArchive,
            hasSourceMedia: false,
            capabilities: [],
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
            bookFormat: .epub,
            hasSourceMedia: hasSourceMedia,
            capabilities: [
                .flags(
                    EntityFlagsCapability(
                        isFavorite: false,
                        isNsfw: false,
                        isOrganized: false,
                        isWanted: isWanted
                    )
                )
            ],
            childrenByKind: [],
            relationships: []
        )
    }
}
