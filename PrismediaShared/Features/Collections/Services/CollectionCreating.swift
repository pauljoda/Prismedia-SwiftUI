import Foundation

/// Creates manual Collections owned by the signed-in user.
protocol CollectionCreating: Sendable {
    /// Creates a manual Collection from the draft.
    ///
    /// - Returns: A thumbnail for the new Collection, suitable for navigation and collection pickers.
    func createCollection(from draft: CollectionDraft) async throws -> EntityThumbnail
}

extension PrismediaAPIClient: CollectionCreating {
    func createCollection(from draft: CollectionDraft) async throws -> EntityThumbnail {
        let collection = try await createCollection(
            title: draft.trimmedTitle,
            description: draft.trimmedDescription,
            mode: .manual,
            isNsfw: draft.isNsfw,
            isShared: draft.isShared
        )
        return EntityThumbnail(id: collection.id, kind: collection.kind, title: collection.title)
    }
}
