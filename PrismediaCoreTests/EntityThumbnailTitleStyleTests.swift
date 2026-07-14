import XCTest

@testable import PrismediaCore

final class EntityThumbnailTitleStyleTests: XCTestCase {
    func testGridTitlesUseTheWebCompactScaleAndTwoLines() {
        let style = EntityThumbnailTitleStyle(layout: .grid, width: 180)

        XCTAssertEqual(style.fontSize, 12)
        XCTAssertEqual(style.lineLimit, 2)
        XCTAssertEqual(style.horizontalPadding, 7)
        XCTAssertEqual(style.verticalPadding, 6)
    }

    func testTitleStyleUsesTheSameContainerBreakpointsAsWeb() {
        let wide = EntityThumbnailTitleStyle(layout: .wall, width: 250)
        let tiny = EntityThumbnailTitleStyle(layout: .grid, width: 140)

        XCTAssertEqual(wide.fontSize, 13)
        XCTAssertEqual(wide.lineLimit, 2)
        XCTAssertEqual(tiny.fontSize, 10)
        XCTAssertEqual(tiny.lineLimit, 1)
        XCTAssertEqual(tiny.horizontalPadding, 6)
        XCTAssertEqual(tiny.verticalPadding, 4)
    }
}
