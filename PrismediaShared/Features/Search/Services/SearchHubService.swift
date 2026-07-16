import Foundation

/// The narrow read contract needed by the Search tab. The feature service is
/// independent of URLSession, so search states stay deterministic in tests and
/// previews.

/// Adapts the authenticated Prismedia client to the Search tab's recent and
/// universal-search use cases.

/// Value state owned by `SearchHubView`. Request generations make stale async
/// results harmless even when an underlying loader ignores cancellation.

/// Focused async search use case. Debouncing belongs here while request
/// identity and presentation state remain value semantics in the view.
@MainActor
public struct SearchHubService {
    private let loader: any SearchHubLoading
    private let recentLimit: Int
    private let searchLimit: Int

    public init(
        loader: any SearchHubLoading,
        recentLimit: Int = 48,
        searchLimit: Int = 48
    ) {
        precondition(recentLimit > 0, "The recent item limit must be positive.")
        precondition(searchLimit > 0, "The search result limit must be positive.")
        self.loader = loader
        self.recentLimit = recentLimit
        self.searchLimit = searchLimit
    }

    public func loadRecent() async throws -> SearchHubPage {
        let response = try await loader.loadRecent(limit: recentLimit)
        try Task.checkCancellation()
        return safePage(from: response)
    }

    public func search(
        query: String,
        filters: SearchHubFilterState = SearchHubFilterState(),
        debounce: Duration
    ) async throws -> SearchHubPage {
        try await search(
            request: SearchHubSearchRequest(
                generation: 0,
                query: query,
                filters: filters,
                cursor: nil
            ),
            debounce: debounce
        )
    }

    public func search(
        request: SearchHubSearchRequest,
        debounce: Duration
    ) async throws -> SearchHubPage {
        if debounce > .zero {
            try await Task.sleep(for: debounce)
        }
        try Task.checkCancellation()
        let response = try await loader.search(
            query: request.query,
            filters: request.filters,
            limit: searchLimit,
            cursor: request.cursor
        )
        try Task.checkCancellation()
        return safePage(from: response, filters: request.filters)
    }

    private func safePage(
        from response: EntityListResponse,
        filters: SearchHubFilterState = SearchHubFilterState()
    ) -> SearchHubPage {
        let items = response.items.filter { item in
            (loader.allowsNsfwContent || !item.isNsfw)
                && filters.includes(item)
        }
        let filteredCount = response.items.count - items.count
        let adjustedTotal = max(0, response.totalCount - filteredCount)
        return SearchHubPage(
            items: items,
            totalCount: max(items.count, adjustedTotal),
            nextCursor: response.nextCursor
        )
    }
}
