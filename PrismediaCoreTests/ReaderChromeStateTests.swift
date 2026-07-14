import XCTest

@testable import PrismediaCore

final class ReaderChromeStateTests: XCTestCase {
    func testContentTapTogglesChromeAndTimeoutHidesIt() {
        var state = ReaderChromeState()

        XCTAssertTrue(state.isVisible)
        XCTAssertTrue(state.shouldScheduleHide)

        state.hide()
        XCTAssertFalse(state.isVisible)

        state.contentTapped()
        XCTAssertTrue(state.isVisible)

        state.contentTapped()
        XCTAssertFalse(state.isVisible)
    }

    func testPresentedReaderPanelPinsChromeUntilDismissed() {
        var state = ReaderChromeState()

        state.setPinned(true)
        state.hide()

        XCTAssertTrue(state.isVisible)
        XCTAssertFalse(state.shouldScheduleHide)

        state.setPinned(false)
        XCTAssertTrue(state.shouldScheduleHide)
        state.hide()
        XCTAssertFalse(state.isVisible)
    }
}
