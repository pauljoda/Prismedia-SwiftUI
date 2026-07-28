import SwiftUI

#if DEBUG
    struct DashboardPreviewLoader: DashboardLoading {
        func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
            let items = PrismediaPreviewData.allEntities.filter { item in
                query.kind == nil || item.kind == query.kind
            }
            return EntityListResponse(items: Array(items.prefix(limit)))
        }
    }

#endif
