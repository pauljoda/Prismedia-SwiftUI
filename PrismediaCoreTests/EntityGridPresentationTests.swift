import XCTest

@testable import PrismediaCore

final class EntityGridPresentationTests: XCTestCase {
    func testEmbeddedGridUsesParentScrollAndInlineControls() {
        XCTAssertFalse(EntityGridPresentation.embedded.ownsVerticalScrollContainer)
        XCTAssertEqual(EntityGridPresentation.embedded.controlPlacement, .inline)
    }

    func testScreenGridOwnsScrollAndNavigationToolbarControls() {
        XCTAssertTrue(EntityGridPresentation.screen.ownsVerticalScrollContainer)
        XCTAssertEqual(EntityGridPresentation.screen.controlPlacement, .navigationToolbar)
    }
}
