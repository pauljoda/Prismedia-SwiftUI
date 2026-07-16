import Foundation

@MainActor
public struct EntityGridActionService {
    private let mutations: any EntityGridMutationServicing

    public init(mutations: any EntityGridMutationServicing) {
        self.mutations = mutations
    }

    public func markNsfw(
        _ isNsfw: Bool,
        items: [EntityThumbnail]
    ) async -> EntityGridMutationResult {
        await perform(items: items) { item in
            try await mutations.markNsfw(isNsfw, item: item)
            return true
        }
    }

    public func removeWanted(
        items: [EntityThumbnail]
    ) async -> EntityGridMutationResult {
        await perform(items: items) { item in
            let response = try await mutations.removeWanted(entityID: item.id)
            guard response.removed == 1 else {
                throw EntityGridActionServiceError.rejected(
                    response.failures.first?.message
                        ?? "The wanted item could not be removed. Refresh and try again."
                )
            }
            return true
        }
    }

    public func addToCollection(
        _ collectionID: UUID,
        items: [EntityThumbnail]
    ) async -> EntityGridMutationResult {
        await perform(items: items) { item in
            try await mutations.addToCollection(
                collectionID: collectionID,
                item: CollectionEntityReference(entityType: item.kind, entityID: item.id)
            )
        }
    }

    public func removeFromCollection(
        _ collectionID: UUID,
        membersByEntityID: [UUID: UUID],
        items: [EntityThumbnail]
    ) async -> EntityGridMutationResult {
        await perform(items: items) { item in
            guard let itemID = membersByEntityID[item.id] else {
                throw EntityGridActionServiceError.rejected("The collection membership is no longer available.")
            }
            return try await mutations.removeCollectionItem(
                collectionID: collectionID,
                itemID: itemID
            )
        }
    }

    private func perform(
        items: [EntityThumbnail],
        operation: (EntityThumbnail) async throws -> Bool
    ) async -> EntityGridMutationResult {
        var succeededIDs = Set<UUID>()
        var failures: [EntityGridMutationFailure] = []
        for item in items {
            do {
                guard try await operation(item) else {
                    throw EntityGridActionServiceError.rejected("The server did not apply this change.")
                }
                succeededIDs.insert(item.id)
            } catch {
                failures.append(
                    EntityGridMutationFailure(
                        entityID: item.id,
                        title: item.title,
                        message: error.localizedDescription
                    )
                )
            }
        }
        return EntityGridMutationResult(succeededIDs: succeededIDs, failures: failures)
    }
}
