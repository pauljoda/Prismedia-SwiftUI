import XCTest

@testable import PrismediaCore

final class EntityImageViewerChromeStateTests: XCTestCase {
    func testMediaTapTogglesChromeAndTimeoutCanHideIt() {
        var state = EntityImageViewerChromeState()

        XCTAssertTrue(state.isVisible)
        XCTAssertTrue(state.shouldScheduleHide)

        state.contentTapped()
        XCTAssertFalse(state.isVisible)

        state.contentTapped()
        XCTAssertTrue(state.isVisible)

        state.hide()
        XCTAssertFalse(state.isVisible)
    }

    func testPagingPreservesHiddenChromeWithoutSchedulingAnotherHide() {
        var state = EntityImageViewerChromeState()
        state.hide()

        state.pageChanged()

        XCTAssertFalse(state.isVisible)
        XCTAssertFalse(state.shouldScheduleHide)
    }

    func testPagingPreservesVisibleChromeAndSchedulesAnotherHide() {
        var state = EntityImageViewerChromeState()

        state.pageChanged()

        XCTAssertTrue(state.isVisible)
        XCTAssertTrue(state.shouldScheduleHide)
    }
}
