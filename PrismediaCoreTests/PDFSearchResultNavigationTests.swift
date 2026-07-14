import XCTest

@testable import PrismediaCore

final class PDFSearchResultNavigationTests: XCTestCase {
    func testNextAndPreviousWrapAcrossSearchResults() {
        XCTAssertEqual(PDFSearchResultNavigation.nextIndex(current: nil, count: 3), 0)
        XCTAssertEqual(PDFSearchResultNavigation.nextIndex(current: 2, count: 3), 0)
        XCTAssertEqual(PDFSearchResultNavigation.previousIndex(current: 0, count: 3), 2)
        XCTAssertEqual(PDFSearchResultNavigation.previousIndex(current: 2, count: 3), 1)
    }

    func testEmptySearchHasNoSelection() {
        XCTAssertNil(PDFSearchResultNavigation.nextIndex(current: nil, count: 0))
        XCTAssertNil(PDFSearchResultNavigation.previousIndex(current: nil, count: 0))
    }
}
