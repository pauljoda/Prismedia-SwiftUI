import Foundation

/// Generated cross-client navigation contract owned by one backend Entity-kind definition.
public struct EntityKindNavigation: Hashable, Sendable {
    public let canonicalBrowseKind: EntityKind
    public let destinationID: String
    public let browsePath: String
    public let detailPathTemplate: String?
    public let requiredAncestorKind: EntityKind?
    public let isTopLevel: Bool

    public init(
        canonicalBrowseKind: EntityKind,
        destinationID: String,
        browsePath: String,
        detailPathTemplate: String?,
        requiredAncestorKind: EntityKind?,
        isTopLevel: Bool
    ) {
        self.canonicalBrowseKind = canonicalBrowseKind
        self.destinationID = destinationID
        self.browsePath = browsePath
        self.detailPathTemplate = detailPathTemplate
        self.requiredAncestorKind = requiredAncestorKind
        self.isTopLevel = isTopLevel
    }
}
