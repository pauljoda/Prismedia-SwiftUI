import XCTest

@testable import PrismediaCore

final class EntityImageViewerDismissPolicyTests: XCTestCase {
    func testConfidentDownwardVerticalSwipeDismisses() {
        XCTAssertTrue(
            EntityImageViewerDismissPolicy.shouldDismiss(
                translation: CGSize(width: 18, height: 132),
                predictedEndTranslation: CGSize(width: 24, height: 168)
            )
        )
    }

    func testHorizontalPagingAndUpwardOrShortSwipesDoNotDismiss() {
        XCTAssertFalse(
            EntityImageViewerDismissPolicy.shouldDismiss(
                translation: CGSize(width: 150, height: 70),
                predictedEndTranslation: CGSize(width: 210, height: 86)
            )
        )
        XCTAssertFalse(
            EntityImageViewerDismissPolicy.shouldDismiss(
                translation: CGSize(width: 10, height: -160),
                predictedEndTranslation: CGSize(width: 12, height: -220)
            )
        )
        XCTAssertFalse(
            EntityImageViewerDismissPolicy.shouldDismiss(
                translation: CGSize(width: 8, height: 54),
                predictedEndTranslation: CGSize(width: 10, height: 78)
            )
        )
    }

    func testInteractiveTranslationTracksOnlyDominantDownwardMovement() {
        XCTAssertEqual(
            EntityImageViewerDismissPolicy.interactiveOffset(
                for: CGSize(width: 20, height: 96)
            ),
            96
        )
        XCTAssertEqual(
            EntityImageViewerDismissPolicy.interactiveOffset(
                for: CGSize(width: 96, height: 20)
            ),
            0
        )
        XCTAssertEqual(
            EntityImageViewerDismissPolicy.interactiveOffset(
                for: CGSize(width: 10, height: -96)
            ),
            0
        )
    }
}
