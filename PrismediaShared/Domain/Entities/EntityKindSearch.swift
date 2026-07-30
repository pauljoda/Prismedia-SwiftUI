import Foundation

/// Generated global-search behavior owned by one backend Entity-kind definition.
public struct EntityKindSearch: Hashable, Sendable {
    public let order: Int
    public let expandsRelationshipResults: Bool

    public init(order: Int, expandsRelationshipResults: Bool) {
        self.order = order
        self.expandsRelationshipResults = expandsRelationshipResults
    }
}
