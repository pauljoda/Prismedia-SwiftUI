import Foundation

#if os(iOS) || os(macOS)
    struct IdentifyEntityGridLoader: EntityGridLoading {
        let browser: any IdentifyEntityBrowsing
        let allowsNsfwContent: Bool

        func load(
            query: EntityListQuery,
            limit: Int,
            search: String?,
            cursor: String?
        ) async throws -> EntityListResponse {
            guard let kind = query.kind ?? query.kinds.first else {
                return EntityListResponse(items: [], nextCursor: nil, totalCount: 0)
            }

            let items = try await browser.entities(
                kind: kind,
                organized: query.organized,
                search: search
            )
            return try await StaticEntityGridLoader(
                items: items,
                allowsNsfwContent: allowsNsfwContent
            ).load(
                query: query,
                limit: limit,
                search: search,
                cursor: cursor
            )
        }
    }
#endif
