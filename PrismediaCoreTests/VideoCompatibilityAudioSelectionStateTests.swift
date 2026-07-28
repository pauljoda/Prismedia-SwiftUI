import XCTest

@testable import PrismediaCore

final class VideoCompatibilityAudioSelectionStateTests: XCTestCase {
    func testInitialSelectionIsConsumedOnlyOnce() {
        var state = VideoCompatibilityAudioSelectionState()
        state.prepare(initialStreamIndex: 2)

        XCTAssertEqual(state.takeInitialStreamIndex(), 2)
        XCTAssertNil(state.takeInitialStreamIndex())
    }

    func testExplicitSelectionSupersedesPendingInitialSelection() {
        var state = VideoCompatibilityAudioSelectionState()
        state.prepare(initialStreamIndex: 2)

        state.explicitSelectionWasRequested()

        XCTAssertNil(state.takeInitialStreamIndex())
    }
}
