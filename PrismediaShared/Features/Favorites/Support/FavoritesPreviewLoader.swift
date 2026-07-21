import Foundation

#if DEBUG
    struct FavoritesPreviewLoader: FavoritesLoading {
        let items: [EntityThumbnail]

        func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
            let matches = items.filter { item in
                (query.kind == nil || item.kind == query.kind)
                    && (query.favorite != true || item.isFavorite)
            }
            return EntityListResponse(
                items: Array(matches.prefix(limit)),
                totalCount: matches.count
            )
        }
    }
#endif
