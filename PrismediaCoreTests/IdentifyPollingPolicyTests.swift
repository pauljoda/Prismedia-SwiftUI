import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyPollingPolicyTests: XCTestCase {
        func testQueuePollingStartsFastThenBacksOffAndTimesOutPerProvider() {
            let policy = IdentifyPollingPolicy()
            XCTAssertEqual(policy.searchInterval(elapsed: 0.2), .milliseconds(300))
            XCTAssertEqual(policy.searchInterval(elapsed: 3.1), .seconds(1))
            XCTAssertFalse(policy.didSearchTimeOut(elapsed: 14.9))
            XCTAssertTrue(policy.didSearchTimeOut(elapsed: 15))
        }

        func testApplyPollingBacksOffAndKeepsProgressVisibleBriefly() {
            let policy = IdentifyPollingPolicy()
            XCTAssertEqual(policy.applyInterval(elapsed: 0.1), .milliseconds(400))
            XCTAssertEqual(policy.applyInterval(elapsed: 4.1), .milliseconds(800))
            XCTAssertEqual(policy.minimumApplyVisibility, .milliseconds(700))
        }
    }
#endif
