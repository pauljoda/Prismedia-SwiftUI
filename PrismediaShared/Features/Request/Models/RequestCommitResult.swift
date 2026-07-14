import Foundation

public struct RequestCommitResult: Hashable, Sendable {
    public let title: String
    public let message: String
    public let navigationIntent: RequestEntityNavigationIntent?
}
