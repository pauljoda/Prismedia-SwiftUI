import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyBulkBehavior {
        static func canAccept(state: IdentifyQueueState, hasProposal: Bool, cascadeRunning: Bool) -> Bool {
            state == .proposal && hasProposal && !cascadeRunning
        }
    }
#endif
