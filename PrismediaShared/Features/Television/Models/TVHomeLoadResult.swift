import SwiftUI

public struct TVHomeLoadResult: Equatable, Sendable {
    public let snapshot: TVHomeSnapshot
    public let failedShelfIDs: Set<String>

    public init(snapshot: TVHomeSnapshot, failedShelfIDs: Set<String>) {
        self.snapshot = snapshot
        self.failedShelfIDs = failedShelfIDs
    }
}
