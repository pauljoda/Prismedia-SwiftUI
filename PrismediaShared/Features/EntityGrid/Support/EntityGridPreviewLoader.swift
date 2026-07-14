import SwiftUI

#if DEBUG
    struct EntityGridPreviewLoader: EntityGridLoading {
        let response: EntityListResponse

        func load(
            query: EntityListQuery,
            limit: Int,
            search: String?,
            cursor: String?
        ) async throws -> EntityListResponse {
            response
        }
    }

#endif
