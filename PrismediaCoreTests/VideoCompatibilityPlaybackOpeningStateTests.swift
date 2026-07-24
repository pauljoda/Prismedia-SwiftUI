import XCTest

@testable import PrismediaCore

final class VideoCompatibilityPlaybackOpeningStateTests: XCTestCase {
    func testPlayRequestedWhileOpeningPreventsDeferredPause() {
        var state = VideoCompatibilityPlaybackOpeningState()
        state.prepare(hasRequestedPlayback: false)

        state.requestPlayback()

        XCTAssertFalse(state.shouldPauseAfterOpening())
    }

    func testUnrequestedPlaybackPausesOnlyAfterItsInitialOpen() {
        var state = VideoCompatibilityPlaybackOpeningState()
        state.prepare(hasRequestedPlayback: false)

        XCTAssertTrue(state.shouldPauseAfterOpening())
        XCTAssertFalse(state.shouldPauseAfterOpening())
    }

    func testPlaybackRequestedBeforeOpeningDoesNotPause() {
        var state = VideoCompatibilityPlaybackOpeningState()

        state.prepare(hasRequestedPlayback: true)

        XCTAssertFalse(state.shouldPauseAfterOpening())
    }
}
