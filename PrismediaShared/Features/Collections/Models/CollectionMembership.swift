import Foundation

/// A collection-local membership row. Its `id` is distinct from the contained
/// entity identifier and is the identifier used by remove and reorder commands.
public struct CollectionMembership: Identifiable, Decodable, Hashable, Sendable {
    public let id: UUID
    public let collectionID: UUID
    public let entityType: EntityKind
    public let entityID: UUID
    public let source: CollectionItemSource
    public let sortOrder: Int
    public let addedAt: Date
    public let entity: EntityThumbnail

    private enum CodingKeys: String, CodingKey {
        case id
        case collectionID = "collectionId"
        case entityType
        case entityID = "entityId"
        case source
        case sortOrder
        case addedAt
        case entity
    }
}
