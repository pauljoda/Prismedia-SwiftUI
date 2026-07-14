import Foundation

public struct RequestEntityNavigationIntent: Hashable, Sendable {
    public let entityID: UUID
    public let entityKind: EntityKind
}
