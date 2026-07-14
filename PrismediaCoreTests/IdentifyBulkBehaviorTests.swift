import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyBulkBehaviorTests: XCTestCase {
        func testAcceptEligibilityRequiresProposalAndNoCascade() {
            XCTAssertTrue(IdentifyBulkBehavior.canAccept(state: .proposal, hasProposal: true, cascadeRunning: false))
            XCTAssertFalse(IdentifyBulkBehavior.canAccept(state: .choice, hasProposal: false, cascadeRunning: false))
            XCTAssertFalse(IdentifyBulkBehavior.canAccept(state: .proposal, hasProposal: true, cascadeRunning: true))
        }
    }
#endif
