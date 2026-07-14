import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyPollingDecisionTests: XCTestCase {
        func testStopsForResultTimeoutAndCancellation() {
            let policy = IdentifyPollingPolicy()
            XCTAssertEqual(
                IdentifyPollingDecision.resolve(state: .searching, elapsed: 1, isCancelled: false, policy: policy),
                .continuePolling)
            XCTAssertEqual(
                IdentifyPollingDecision.resolve(state: .proposal, elapsed: 1, isCancelled: false, policy: policy),
                .complete)
            XCTAssertEqual(
                IdentifyPollingDecision.resolve(state: .searching, elapsed: 15, isCancelled: false, policy: policy),
                .timedOut)
            XCTAssertEqual(
                IdentifyPollingDecision.resolve(state: .searching, elapsed: 1, isCancelled: true, policy: policy),
                .cancelled)
        }
    }
#endif
