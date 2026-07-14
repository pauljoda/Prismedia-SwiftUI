import XCTest

@testable import PrismediaCore

final class BookReaderFormatPolicyTests: XCTestCase {
    func testKnownBookFormatsDispatchToTheirNativeReader() {
        XCTAssertEqual(BookReaderFormatPolicy.route(for: nil), .unavailable)
        XCTAssertEqual(BookReaderFormatPolicy.route(for: .imageArchive), .comic)
        XCTAssertEqual(BookReaderFormatPolicy.route(for: .pdf), .pdf)
        XCTAssertEqual(BookReaderFormatPolicy.route(for: .epub), .epub)
    }

    func testUnknownBookFormatRemainsTruthfullyUnsupported() {
        let format = BookFormat(rawValue: "drm-protected")

        XCTAssertEqual(BookReaderFormatPolicy.route(for: format), .unsupported(format))
    }

    func testNestedBookEntitiesRouteThroughTheComicReaderWithoutRepeatingTheRootFormat() {
        XCTAssertEqual(
            BookReaderFormatPolicy.route(for: .bookVolume, format: nil),
            .comic
        )
        XCTAssertEqual(
            BookReaderFormatPolicy.route(for: .bookChapter, format: nil),
            .comic
        )
        XCTAssertEqual(
            BookReaderFormatPolicy.route(for: .book, format: nil),
            .unavailable
        )
    }
}
