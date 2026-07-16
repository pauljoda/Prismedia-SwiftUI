import Foundation

public struct SearchHubSnapshot: Equatable, Sendable {
    public private(set) var recentItems: [EntityThumbnail]
    public private(set) var searchResults: [EntityThumbnail]
    public private(set) var recentTotalCount: Int
    public private(set) var searchTotalCount: Int
    public private(set) var recentState: SearchHubState
    public private(set) var searchState: SearchHubState
    public private(set) var isLoadingNextSearchPage: Bool
    public private(set) var searchPaginationErrorMessage: String?
    public private(set) var searchNextCursor: String?

    public var hasMoreSearchResults: Bool { searchNextCursor != nil }

    private var recentGeneration: Int
    private var searchGeneration: Int
    private var activeSearchFilters: SearchHubFilterState

    public init() {
        recentItems = []
        searchResults = []
        recentTotalCount = 0
        searchTotalCount = 0
        recentState = .idle
        searchState = .idle
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        searchNextCursor = nil
        recentGeneration = 0
        searchGeneration = 0
        activeSearchFilters = SearchHubFilterState()
    }

    public func displayedItems(for query: String) -> [EntityThumbnail] {
        Self.isSearchActive(query) ? searchResults : recentItems
    }

    public func activeState(for query: String) -> SearchHubState {
        Self.isSearchActive(query) ? searchState : recentState
    }

    public mutating func beginRecentLoad() -> SearchHubRecentRequest {
        recentGeneration &+= 1
        recentState = .loading
        return SearchHubRecentRequest(generation: recentGeneration)
    }

    @discardableResult
    public mutating func receiveRecent(
        _ page: SearchHubPage,
        for request: SearchHubRecentRequest
    ) -> Bool {
        guard request.generation == recentGeneration else { return false }
        recentItems = page.items
        recentTotalCount = page.totalCount
        recentState = page.items.isEmpty ? .empty : .content
        return true
    }

    @discardableResult
    public mutating func failRecent(for request: SearchHubRecentRequest) -> Bool {
        guard request.generation == recentGeneration else { return false }
        recentItems = []
        recentTotalCount = 0
        recentState = .failed("Your library couldn’t be loaded. Try again.")
        return true
    }

    public mutating func cancelRecent(for request: SearchHubRecentRequest) {
        guard request.generation == recentGeneration else { return }
        recentState = recentItems.isEmpty ? .idle : .content
    }

    public mutating func beginSearch(
        query: String,
        filters: SearchHubFilterState = SearchHubFilterState()
    ) -> SearchHubSearchRequest? {
        let normalizedQuery = Self.normalized(query)
        guard !normalizedQuery.isEmpty else {
            clearSearch()
            return nil
        }

        let filtersChanged = activeSearchFilters != filters
        searchGeneration &+= 1
        activeSearchFilters = filters
        searchState = .loading
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        searchNextCursor = nil
        if filtersChanged {
            searchResults = []
            searchTotalCount = 0
        }
        return SearchHubSearchRequest(
            generation: searchGeneration,
            query: normalizedQuery,
            filters: filters,
            cursor: nil
        )
    }

    public mutating func beginNextSearchPage(
        currentQuery: String
    ) -> SearchHubSearchRequest? {
        let normalizedQuery = Self.normalized(currentQuery)
        guard
            !normalizedQuery.isEmpty,
            let searchNextCursor,
            !isLoadingNextSearchPage,
            searchState == .content
        else { return nil }
        isLoadingNextSearchPage = true
        searchPaginationErrorMessage = nil
        return SearchHubSearchRequest(
            generation: searchGeneration,
            query: normalizedQuery,
            filters: activeSearchFilters,
            cursor: searchNextCursor
        )
    }

    @discardableResult
    public mutating func receiveSearch(
        _ page: SearchHubPage,
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) -> Bool {
        guard isCurrent(request, query: currentQuery) else { return false }
        searchResults = page.items
        searchTotalCount = page.totalCount
        searchNextCursor = page.nextCursor
        searchState = page.items.isEmpty && page.nextCursor == nil ? .empty : .content
        return true
    }

    @discardableResult
    public mutating func receiveNextSearchPage(
        _ page: SearchHubPage,
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) -> Bool {
        guard isCurrent(request, query: currentQuery), request.cursor != nil else { return false }
        searchResults = Self.unique(searchResults + page.items)
        searchTotalCount = max(searchResults.count, page.totalCount)
        searchNextCursor = page.nextCursor
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        searchState = searchResults.isEmpty && searchNextCursor == nil ? .empty : .content
        return true
    }

    @discardableResult
    public mutating func failNextSearchPage(
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) -> Bool {
        guard isCurrent(request, query: currentQuery), request.cursor != nil else { return false }
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = "More results couldn’t be loaded."
        return true
    }

    @discardableResult
    public mutating func failSearch(
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) -> Bool {
        guard isCurrent(request, query: currentQuery) else { return false }
        searchResults = []
        searchTotalCount = 0
        searchNextCursor = nil
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        searchState = .failed("Search couldn’t be completed. Try again.")
        return true
    }

    public mutating func cancelSearch(
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) {
        guard isCurrent(request, query: currentQuery) else { return }
        searchState = searchResults.isEmpty ? .idle : .content
    }

    public mutating func cancelNextSearchPage(
        for request: SearchHubSearchRequest,
        currentQuery: String
    ) {
        guard isCurrent(request, query: currentQuery), request.cursor != nil else { return }
        isLoadingNextSearchPage = false
    }

    public mutating func clearSearch() {
        searchGeneration &+= 1
        searchResults = []
        searchTotalCount = 0
        searchNextCursor = nil
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        searchState = .idle
        activeSearchFilters = SearchHubFilterState()
    }

    public mutating func reset() {
        recentGeneration &+= 1
        searchGeneration &+= 1
        recentItems = []
        searchResults = []
        recentTotalCount = 0
        searchTotalCount = 0
        searchNextCursor = nil
        isLoadingNextSearchPage = false
        searchPaginationErrorMessage = nil
        recentState = .idle
        searchState = .idle
        activeSearchFilters = SearchHubFilterState()
    }

    public static func isSearchActive(_ query: String) -> Bool {
        !normalized(query).isEmpty
    }

    public static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isCurrent(_ request: SearchHubSearchRequest, query: String) -> Bool {
        request.generation == searchGeneration
            && request.query == Self.normalized(query)
    }

    private static func unique(_ candidates: [EntityThumbnail]) -> [EntityThumbnail] {
        var seen = Set<UUID>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
}
