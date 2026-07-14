import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyPollingPolicy: Hashable, Sendable {
        let fastSearchWindow: TimeInterval
        let providerTimeout: TimeInterval
        let fastApplyWindow: TimeInterval
        let minimumApplyVisibilitySeconds: TimeInterval

        var minimumApplyVisibility: Duration { .milliseconds(Int64(minimumApplyVisibilitySeconds * 1_000)) }

        init(
            fastSearchWindow: TimeInterval = 3,
            providerTimeout: TimeInterval = 15,
            fastApplyWindow: TimeInterval = 4,
            minimumApplyVisibilitySeconds: TimeInterval = 0.7
        ) {
            self.fastSearchWindow = fastSearchWindow
            self.providerTimeout = providerTimeout
            self.fastApplyWindow = fastApplyWindow
            self.minimumApplyVisibilitySeconds = minimumApplyVisibilitySeconds
        }

        func searchInterval(elapsed: TimeInterval) -> Duration {
            elapsed <= fastSearchWindow ? .milliseconds(300) : .seconds(1)
        }

        func applyInterval(elapsed: TimeInterval) -> Duration {
            elapsed <= fastApplyWindow ? .milliseconds(400) : .milliseconds(800)
        }

        func didSearchTimeOut(elapsed: TimeInterval) -> Bool { elapsed >= providerTimeout }
    }
#endif
