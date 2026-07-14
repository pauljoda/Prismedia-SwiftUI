import Foundation

/// Infrastructure adapter for collection management and membership use cases.
public struct PrismediaCollectionService: CollectionItemsLoading, CollectionMembershipLoading,
    CollectionManaging, CollectionMembershipMutating, Sendable
{
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
        try await client.fetchCollectionItems(collectionID: collectionID)
    }

    public func loadCollectionMemberships(collectionID: UUID) async throws -> [CollectionMembership] {
        try await client.fetchCollectionMemberships(collectionID: collectionID)
    }

    public func createCollection(_ request: CollectionWriteRequest) async throws -> CollectionDefinition {
        try await client.createCollection(request)
    }

    public func updateCollection(
        id: UUID,
        request: CollectionWriteRequest
    ) async throws -> CollectionDefinition {
        try await client.updateCollection(id: id, request: request)
    }

    public func deleteCollection(id: UUID) async throws -> UUID {
        try await client.deleteCollection(id: id)
    }

    public func addCollectionMembers(
        collectionID: UUID,
        items: [CollectionEntityReference]
    ) async throws -> Int {
        try await client.addCollectionMembers(collectionID: collectionID, items: items)
    }

    public func removeCollectionMembers(collectionID: UUID, itemIDs: [UUID]) async throws -> Int {
        try await client.removeCollectionMembers(collectionID: collectionID, itemIDs: itemIDs)
    }

    public func reorderCollectionMembers(collectionID: UUID, itemIDs: [UUID]) async throws -> Int {
        try await client.reorderCollectionMembers(collectionID: collectionID, itemIDs: itemIDs)
    }
}
