import Foundation

/// A shell selection that is guaranteed to pair a destination with its mode.
public struct SearchHubNavigationTarget: Hashable, Sendable {
    public let mode: AppMode
    public let destination: AppDestination

    public init(mode: AppMode, destination: AppDestination) {
        precondition(
            mode.destination(id: destination.id) != nil,
            "A search target's destination must belong to its mode."
        )

        self.mode = mode
        self.destination = destination
    }
}
