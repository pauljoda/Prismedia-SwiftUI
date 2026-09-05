import Foundation
import XCTest

@testable import PrismediaCore

final class PluginCatalogLoadStateTests: XCTestCase {
    func testCancellationPreservesPreviouslyLoadedItemsWithoutFailure() {
        for error: any Error in [CancellationError(), URLError(.cancelled)] {
            var state = PluginCatalogLoadState<String>()
            let initial = state.begin()
            state.succeed(["installed"], request: initial)
            let refresh = state.begin()
            state.fail(error, request: refresh, isCancelled: false)
            XCTAssertEqual(state.items, ["installed"])
            XCTAssertNil(state.errorMessage)
            XCTAssertFalse(state.isLoading)
        }
    }

    func testCancelledTaskDoesNotPublishResponseOrUnrelatedError() {
        var state = PluginCatalogLoadState<String>()
        let request = state.begin()
        state.succeed(["stale"], request: request, isCancelled: true)
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertFalse(state.isLoading)
        let retry = state.begin()
        state.fail(URLError(.notConnectedToInternet), request: retry, isCancelled: true)
        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(state.isLoading)
    }

    func testSupersededRequestCannotChangeCurrentItemsFailureOrLoading() {
        var state = PluginCatalogLoadState<String>()
        let old = state.begin()
        let current = state.begin()
        state.fail(URLError(.timedOut), request: old, isCancelled: false)
        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.errorMessage)
        state.succeed(["current"], request: current)
        state.succeed(["old"], request: old)
        XCTAssertEqual(state.items, ["current"])
        XCTAssertFalse(state.isLoading)
    }

    func testFailureRetainsItemsAndSuccessfulRetryClearsError() {
        var state = PluginCatalogLoadState<String>()
        let initial = state.begin()
        state.succeed(["cached"], request: initial)
        let refresh = state.begin()
        state.fail(URLError(.timedOut), request: refresh, isCancelled: false)
        XCTAssertEqual(state.items, ["cached"])
        XCTAssertNotNil(state.errorMessage)
        XCTAssertFalse(state.isLoading)
        let retry = state.begin()
        XCTAssertNil(state.errorMessage)
        state.succeed(["fresh"], request: retry)
        XCTAssertEqual(state.items, ["fresh"])
        XCTAssertNil(state.errorMessage)
    }
}
