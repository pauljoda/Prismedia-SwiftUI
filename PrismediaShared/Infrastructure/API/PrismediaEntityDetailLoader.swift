import Foundation

/// Infrastructure adapter for the feature-owned Entity Detail ports.
public struct PrismediaEntityDetailLoader: EntityDetailLoading, EntityDetailMutating, CollectionItemsLoading,
    EntityImageSourceLoading, Sendable
{
    let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadEntity(id: UUID) async throws -> EntityDetail {
        try await client.fetchEntity(id: id)
    }

    public func loadEntity(id: UUID, kind: EntityKind) async throws -> EntityDetail {
        try await client.fetchEntity(id: id, kind: kind)
    }

    public func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
        try await client.fetchCollectionItems(collectionID: collectionID)
    }

    public func loadEntitySourceData(id: UUID) async throws -> Data {
        try await client.entitySourceData(id: id)
    }

    public func updateRating(id: UUID, value: Int?) async throws -> EntityDetail {
        try await client.updateEntityRating(id: id, value: value)
    }

    public func updateFlags(
        id: UUID,
        isFavorite: Bool?,
        isOrganized: Bool?
    ) async throws -> EntityDetail {
        try await client.updateEntityFlags(
            id: id,
            isFavorite: isFavorite,
            isOrganized: isOrganized
        )
    }
}
