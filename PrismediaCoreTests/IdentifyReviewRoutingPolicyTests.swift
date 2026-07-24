import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyReviewRoutingPolicyTests: XCTestCase {
        func testReviewRequiresCompletedProposalStateAndProposalContent() {
            XCTAssertFalse(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .searching,
                    hasProposal: true,
                    explicitlyShowsSearch: false,
                    isSearching: false,
                    isSeeking: false
                )
            )
            XCTAssertFalse(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .proposal,
                    hasProposal: false,
                    explicitlyShowsSearch: false,
                    isSearching: false,
                    isSeeking: false
                )
            )
            XCTAssertTrue(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .proposal,
                    hasProposal: true,
                    explicitlyShowsSearch: false,
                    isSearching: false,
                    isSeeking: false
                )
            )
        }

        func testReviewDoesNotReplacePreservedSearchOrOpenDuringSearchMutation() {
            XCTAssertFalse(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .proposal,
                    hasProposal: true,
                    explicitlyShowsSearch: true,
                    isSearching: false,
                    isSeeking: false
                )
            )
            XCTAssertFalse(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .proposal,
                    hasProposal: true,
                    explicitlyShowsSearch: false,
                    isSearching: true,
                    isSeeking: false
                )
            )
            XCTAssertFalse(
                IdentifyReviewRoutingPolicy.shouldPresentReview(
                    queueState: .proposal,
                    hasProposal: true,
                    explicitlyShowsSearch: false,
                    isSearching: false,
                    isSeeking: true
                )
            )
        }
    }
#endif
