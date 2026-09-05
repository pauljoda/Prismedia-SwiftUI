import Foundation
import XCTest

@testable import PrismediaCore

final class AdministrativeCollectionLoadStateTests: XCTestCase {
    func testDependentEditingRequiresAnAcknowledgedCurrentLoadIncludingEmptyCollections() {
        var state = AdministrativeCollectionLoadState<String>()
        XCTAssertFalse(state.isReady)
        let initial = state.begin()
        state.succeed([], request: initial)
        XCTAssertTrue(state.isReady)
        let refresh = state.begin()
        XCTAssertFalse(state.isReady)
        state.fail(URLError(.timedOut), request: refresh, isCancelled: false)
        XCTAssertFalse(state.isReady)
        let retry = state.begin()
        state.succeed(["current"], request: retry)
        XCTAssertTrue(state.isReady)
    }

    func testCancelledAndSupersededReadsCannotEnableDependentEditing() {
        var state = AdministrativeCollectionLoadState<String>()
        let old = state.begin()
        let current = state.begin()
        state.succeed(["old"], request: old)
        XCTAssertFalse(state.isReady)
        state.succeed(["cancelled"], request: current, isCancelled: true)
        XCTAssertFalse(state.isReady)
        let retry = state.begin()
        state.fail(CancellationError(), request: retry, isCancelled: false)
        XCTAssertFalse(state.isReady)
    }

    func testChangingCollectionClearsOldItemsAndRejectsItsPendingResponse() {
        var state = AdministrativeCollectionLoadState<String>()
        let oldFolder = state.begin()
        state.succeed(["old-file"], request: oldFolder)
        let oldRefresh = state.begin()
        let newFolder = state.begin(clearingItems: true)
        XCTAssertTrue(state.items.isEmpty)
        state.succeed(["wrong-folder-file"], request: oldRefresh)
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertTrue(state.isLoading)
        state.succeed(["new-file"], request: newFolder)
        XCTAssertEqual(state.items, ["new-file"])
    }

    func testCancellationPreservesPreviouslyLoadedItemsWithoutFailure() {
        for error: any Error in [CancellationError(), URLError(.cancelled)] {
            var state = AdministrativeCollectionLoadState<String>()
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
        var state = AdministrativeCollectionLoadState<String>()
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
        var state = AdministrativeCollectionLoadState<String>()
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
        var state = AdministrativeCollectionLoadState<String>()
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
