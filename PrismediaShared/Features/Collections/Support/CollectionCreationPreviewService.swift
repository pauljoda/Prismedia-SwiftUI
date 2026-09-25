import Foundation

#if DEBUG
    /// In-memory Collection creation for previews. It never touches the network.
    struct CollectionCreationPreviewService: CollectionCreating {
        func createCollection(from draft: CollectionDraft) async throws -> EntityThumbnail {
            EntityThumbnail(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                kind: .collection,
                title: draft.trimmedTitle,
                isNsfw: draft.isNsfw
            )
        }
    }
#endif
