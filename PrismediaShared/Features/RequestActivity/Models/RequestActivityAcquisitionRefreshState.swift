import Foundation

struct RequestActivityAcquisitionRefreshState: Equatable, Sendable {
    private(set) var consecutiveFailures = 0
    private(set) var message: String?

    init() {}

    #if DEBUG
        init(previewMessage: String?) {
            consecutiveFailures = previewMessage == nil ? 0 : 3
            message = previewMessage
        }
    #endif

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
