import SwiftUI

#if DEBUG
    struct SearchHubPreviewLoader: SearchHubLoading {
        let recent: SearchHubPreviewResponse
        let search: SearchHubPreviewResponse
        let allowsNsfwContent = false

        init(
            recent: SearchHubPreviewResponse = .items(PrismediaPreviewData.allEntities),
            search: SearchHubPreviewResponse = .items(PrismediaPreviewData.allEntities)
        ) {
            self.recent = recent
            self.search = search
        }

        func loadRecent(limit: Int) async throws -> EntityListResponse {
            try await response(recent, limit: limit)
        }

        func search(query: String, limit: Int, cursor: String?) async throws -> EntityListResponse {
            try await response(search, limit: limit)
        }

        private func response(_ response: SearchHubPreviewResponse, limit: Int) async throws -> EntityListResponse {
            switch response {
            case .items(let items, let totalCount):
                return EntityListResponse(
                    items: Array(items.prefix(limit)),
                    totalCount: totalCount ?? items.count
                )
            case .failure:
                throw URLError(.cannotConnectToHost)
            case .loading:
                try await Task.sleep(for: .seconds(60))
                return EntityListResponse(items: [])
            }
        }
    }

#endif
