import XCTest

@testable import PrismediaCore

final class BookProgressLoadingStateTests: XCTestCase {
    func testOlderCancelledLoadCannotFinishANewerRefresh() {
        var state = BookProgressLoadingState()
        let initialLoad = state.begin()
        let refresh = state.begin()

        state.finish(initialLoad)
        XCTAssertTrue(state.isLoading)

        state.finish(refresh)
        XCTAssertFalse(state.isLoading)
    }
}
