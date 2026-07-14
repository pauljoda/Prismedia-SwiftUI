import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyPollingDecision: Hashable, Sendable {
        case continuePolling
        case complete
        case timedOut
        case cancelled

        static func resolve(
            state: IdentifyQueueState,
            elapsed: TimeInterval,
            isCancelled: Bool,
            policy: IdentifyPollingPolicy
        ) -> IdentifyPollingDecision {
            if isCancelled { return .cancelled }
            if !state.isBusy { return .complete }
            if policy.didSearchTimeOut(elapsed: elapsed) { return .timedOut }
            return .continuePolling
        }
    }
#endif
