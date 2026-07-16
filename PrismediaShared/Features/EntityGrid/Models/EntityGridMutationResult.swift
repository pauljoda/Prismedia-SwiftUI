import Foundation

public struct EntityGridMutationResult: Equatable, Sendable {
    public let succeededIDs: Set<UUID>
    public let failures: [EntityGridMutationFailure]

    public init(
        succeededIDs: Set<UUID> = [],
        failures: [EntityGridMutationFailure] = []
    ) {
        self.succeededIDs = succeededIDs
        self.failures = failures
    }

    public var isCompleteSuccess: Bool {
        failures.isEmpty && !succeededIDs.isEmpty
    }
}
