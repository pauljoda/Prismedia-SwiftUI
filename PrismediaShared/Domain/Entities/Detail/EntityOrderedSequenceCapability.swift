import Foundation

/// Generic ordered-container or ordered-item participation projected by the backend.
public struct EntityOrderedSequenceCapability: Decodable, Hashable, Sendable {
    public let role: EntitySequenceRole
    public let itemKind: EntityKind
    public let containerKinds: [EntityKind]

    public init(role: EntitySequenceRole, itemKind: EntityKind, containerKinds: [EntityKind]) {
        self.role = role
        self.itemKind = itemKind
        self.containerKinds = containerKinds
    }
}
