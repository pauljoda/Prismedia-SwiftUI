import Foundation

public protocol EntityGridMutationServicing: Sendable {
    func loadCollectionOptions() async throws -> [EntityThumbnail]
    func addToCollection(collectionID: UUID, item: CollectionEntityReference) async throws -> Bool
    func markNsfw(_ isNsfw: Bool, item: EntityThumbnail) async throws
    func removeWanted(entityID: UUID) async throws -> WantedRemovalResponse
    func removeCollectionItem(collectionID: UUID, itemID: UUID) async throws -> Bool
}

extension PrismediaAPIClient: EntityGridMutationServicing {
    public func loadCollectionOptions() async throws -> [EntityThumbnail] {
        try await listCollections().items
    }

    public func addToCollection(
        collectionID: UUID,
        item: CollectionEntityReference
    ) async throws -> Bool {
        try await addToCollection(collectionID: collectionID, items: [item]) == 1
    }

    public func markNsfw(_ isNsfw: Bool, item: EntityThumbnail) async throws {
        _ = try await updateEntityFlags(
            id: item.id,
            isFavorite: nil,
            isNsfw: isNsfw,
            isOrganized: nil
        )
    }
}
