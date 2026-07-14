#if DEBUG
    import Foundation

    struct MusicLibraryPreviewLoader: EntityGridLoading {
        let items: [EntityThumbnail]
        func load(query: EntityListQuery, limit: Int, search: String?, cursor: String?) async throws
            -> EntityListResponse
        {
            EntityListResponse(items: items)
        }
    }
#endif
