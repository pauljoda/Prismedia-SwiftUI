import Foundation

public struct WantedRemovalResponse: Decodable, Equatable, Sendable {
    public let removed: Int
    public let failures: [WantedRemovalFailure]

    public init(removed: Int, failures: [WantedRemovalFailure]) {
        self.removed = removed
        self.failures = failures
    }
}
