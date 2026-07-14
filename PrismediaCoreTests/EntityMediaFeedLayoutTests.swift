import XCTest

@testable import PrismediaCore

final class EntityMediaFeedLayoutTests: XCTestCase {
    func testFeedRowsUseCompactSeparation() {
        XCTAssertEqual(EntityMediaFeedLayout.horizontalInset, 8)
        XCTAssertEqual(EntityMediaFeedLayout.interItemSpacing, 8)
        XCTAssertEqual(EntityMediaFeedLayout.cornerRadius, 8)
    }

    func testPortraitAndLandscapeRowsFollowTheirOwnIntrinsicDimensions() {
        let portraitHeight = EntityMediaFeedLayout.itemHeight(
            contentWidth: 390,
            aspectRatio: 2.0 / 3.0
        )
        let landscapeHeight = EntityMediaFeedLayout.itemHeight(
            contentWidth: 390,
            aspectRatio: 16.0 / 9.0
        )

        XCTAssertEqual(portraitHeight, 585, accuracy: 0.001)
        XCTAssertEqual(landscapeHeight, 219.375, accuracy: 0.001)
        XCTAssertGreaterThan(portraitHeight, landscapeHeight)
    }

    func testEveryValidAspectRatioIsPreservedExactly() {
        XCTAssertEqual(EntityMediaFeedLayout.rowAspectRatio(0.2), 0.2, accuracy: 0.001)
        XCTAssertEqual(EntityMediaFeedLayout.rowAspectRatio(2.0 / 3.0), 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(EntityMediaFeedLayout.rowAspectRatio(16.0 / 9.0), 16.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(EntityMediaFeedLayout.rowAspectRatio(5), 5, accuracy: 0.001)

        XCTAssertEqual(
            EntityMediaFeedLayout.itemHeight(contentWidth: 390, aspectRatio: 0.2),
            1_950,
            accuracy: 0.001
        )
        XCTAssertEqual(
            EntityMediaFeedLayout.itemHeight(contentWidth: 390, aspectRatio: 5),
            78,
            accuracy: 0.001
        )
    }

    func testInvalidDimensionsUseTheFallbackAspectRatio() {
        XCTAssertEqual(
            EntityMediaFeedLayout.aspectRatio(
                pixelWidth: 0,
                pixelHeight: 1_080,
                fallback: 4.0 / 3.0
            ),
            4.0 / 3.0,
            accuracy: 0.001
        )
    }

    func testValidDimensionsDetermineTheMediaAspectRatio() {
        XCTAssertEqual(
            EntityMediaFeedLayout.aspectRatio(
                pixelWidth: 1_080,
                pixelHeight: 1_920,
                fallback: 1
            ),
            9.0 / 16.0,
            accuracy: 0.001
        )
    }
}
