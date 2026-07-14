#if DEBUG
    import Foundation

    struct MusicCollectionPreviewLoader: CollectionItemsLoading, EntityDetailLoading {
        static let collection = EntityThumbnail(
            id: UUID(uuidString: "90000000-0000-0000-0000-000000000001")!,
            kind: .collection,
            title: "Evening Listening"
        )
        static let album = EntityThumbnail(
            id: UUID(uuidString: "90000000-0000-0000-0000-000000000002")!,
            kind: .audioLibrary,
            title: "Night Drive"
        )
        static let track = EntityThumbnail(
            id: UUID(uuidString: "90000000-0000-0000-0000-000000000003")!,
            kind: .audioTrack,
            title: "City Lights",
            sortOrder: 1,
            meta: [.init(icon: "duration", label: "3:42")]
        )

        func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
            collectionID == Self.collection.id ? [Self.album] : []
        }

        func loadEntity(id: UUID) async throws -> EntityDetail {
            EntityDetail(
                id: Self.album.id,
                kind: .audioLibrary,
                title: Self.album.title,
                parentEntityID: nil,
                sortOrder: nil,
                hasSourceMedia: true,
                capabilities: [],
                childrenByKind: [
                    EntityGroup(
                        kind: .audioTrack,
                        label: "Tracks",
                        entities: [Self.track],
                        code: nil
                    )
                ],
                relationships: []
            )
        }
    }
#endif
