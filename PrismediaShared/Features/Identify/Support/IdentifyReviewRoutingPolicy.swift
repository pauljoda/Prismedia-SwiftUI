import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyReviewRoutingPolicy {
        static func shouldPresentReview(
            queueState: IdentifyQueueState,
            hasProposal: Bool,
            explicitlyShowsSearch: Bool,
            isSearching: Bool,
            isSeeking: Bool
        ) -> Bool {
            queueState == .proposal
                && hasProposal
                && !explicitlyShowsSearch
                && !isSearching
                && !isSeeking
        }
    }
#endif
