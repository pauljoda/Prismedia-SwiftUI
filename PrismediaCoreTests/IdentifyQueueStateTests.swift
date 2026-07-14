import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyQueueStateTests: XCTestCase {
        func testMapsServerStatesToNativePresentationAndCapabilities() {
            XCTAssertEqual(IdentifyQueueState(rawServerValue: "proposal"), .proposal)
            XCTAssertEqual(IdentifyQueueState(rawServerValue: "search"), .choice)
            XCTAssertEqual(IdentifyQueueState(rawServerValue: "SEARCHING"), .searching)
            XCTAssertEqual(IdentifyQueueState(rawServerValue: "future-state"), .unknown("future-state"))
            XCTAssertTrue(IdentifyQueueState.proposal.isReviewable)
            XCTAssertTrue(IdentifyQueueState.searching.isBusy)
            XCTAssertFalse(IdentifyQueueState.error.isBusy)
        }
    }
#endif
