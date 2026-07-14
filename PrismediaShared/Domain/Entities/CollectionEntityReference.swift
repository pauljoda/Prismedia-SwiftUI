import Foundation

public struct CollectionEntityReference: Encodable, Hashable, Sendable {
    public let entityType: EntityKind
    public let entityID: UUID

    public init(entityType: EntityKind, entityID: UUID) {
        self.entityType = entityType
        self.entityID = entityID
    }

    private enum CodingKeys: String, CodingKey {
        case entityType
        case entityID = "entityId"
    }
}
