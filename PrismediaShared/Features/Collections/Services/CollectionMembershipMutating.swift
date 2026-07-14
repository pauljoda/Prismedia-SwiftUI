import Foundation

public protocol CollectionMembershipMutating: Sendable {
    func addCollectionMembers(
        collectionID: UUID,
        items: [CollectionEntityReference]
    ) async throws -> Int
    func removeCollectionMembers(collectionID: UUID, itemIDs: [UUID]) async throws -> Int
    func reorderCollectionMembers(collectionID: UUID, itemIDs: [UUID]) async throws -> Int
}
