import XCTest

@testable import PrismediaCore

final class EntityImageMediaInteractionTests: XCTestCase {
    func testFeedLeavesOnlyVideoProgressInteractiveChromeHidden() {
        XCTAssertFalse(EntityImageMediaInteraction.feed.allowsPlaybackToggle)
        XCTAssertFalse(EntityImageMediaInteraction.feed.showsPlaybackControls)
        XCTAssertTrue(EntityImageMediaInteraction.feed.showsVideoProgress)
        XCTAssertFalse(EntityImageMediaInteraction.feed.allowsZoom)
    }

    func testViewerKeepsExplicitPlaybackControlsAndZoom() {
        XCTAssertTrue(EntityImageMediaInteraction.viewer.allowsPlaybackToggle)
        XCTAssertTrue(EntityImageMediaInteraction.viewer.showsPlaybackControls)
        XCTAssertTrue(EntityImageMediaInteraction.viewer.showsVideoProgress)
        XCTAssertTrue(EntityImageMediaInteraction.viewer.allowsZoom)
    }
}
