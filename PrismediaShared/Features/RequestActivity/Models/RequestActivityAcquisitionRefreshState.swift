import Foundation

struct RequestActivityAcquisitionRefreshState: Equatable, Sendable {
    private(set) var consecutiveFailures = 0
    private(set) var message: String?

    mutating func recordFailure() {
        consecutiveFailures += 1
        guard consecutiveFailures >= 3 else { return }
        message = "Live updates are failing. Prismedia will keep retrying in the background."
    }

    mutating func recordSuccess() {
        consecutiveFailures = 0
        message = nil
    }

    mutating func dismiss() {
        message = nil
    }
}
