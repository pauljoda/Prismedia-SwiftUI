import Foundation

extension EntityGridLoading {
    public var allowsNsfwContent: Bool { false }
}

/// Adapts the authenticated API client to the grid's cursor-paged read contract.
/// Cursor transport stays here so feature state never assembles requests.

/// A value snapshot owned by the SwiftUI screen. It contains presentation state
/// and deterministic transitions, but no transport or long-running tasks.

/// Focused async use case for loading and sanitizing grid pages. SwiftUI owns
/// the snapshot; this service owns request execution and paging policy.
@MainActor
public struct EntityGridService {
    private let loader: any EntityGridLoading

    public init(loader: any EntityGridLoading) {
        self.loader = loader
    }

    public func loadFirstPage(_ request: EntityGridPageRequest) async throws -> EntityGridPage {
        let response = try await loadResponse(for: request, cursor: nil)
        try Task.checkCancellation()
        return page(from: response, request: request, excludedNsfwIDs: request.excludedNsfwIDs)
    }

    public func loadNextVisiblePage(_ request: EntityGridPageRequest) async throws -> EntityGridPage {
        var cursor = request.cursor
        var excludedNsfwIDs = request.excludedNsfwIDs
        var visitedCursors = Set<String>()
        var lastPage = EntityGridPage(
            items: [],
            nextCursor: cursor,
            totalCount: request.existingItemIDs.count,
            excludedNsfwIDs: excludedNsfwIDs
        )

        while let currentCursor = cursor, visitedCursors.insert(currentCursor).inserted {
            let response = try await loadResponse(for: request, cursor: currentCursor)
            try Task.checkCancellation()
            let loadedPage = page(
                from: response,
                request: request,
                excludedNsfwIDs: excludedNsfwIDs
            )
            lastPage = loadedPage
            excludedNsfwIDs = loadedPage.excludedNsfwIDs

            guard loadedPage.items.isEmpty else { return loadedPage }
            cursor = loadedPage.nextCursor
        }

        return lastPage
    }

    private func loadResponse(
        for request: EntityGridPageRequest,
        cursor: String?
    ) async throws -> EntityListResponse {
        try await loader.load(
            query: request.query,
            limit: request.pageSize,
            search: request.search,
            cursor: cursor
        )
    }

    private func page(
        from response: EntityListResponse,
        request: EntityGridPageRequest,
        excludedNsfwIDs: Set<UUID>
    ) -> EntityGridPage {
        var excludedNsfwIDs = excludedNsfwIDs
        let safeItems: [EntityThumbnail]

        if loader.allowsNsfwContent {
            safeItems = response.items
        } else {
            excludedNsfwIDs.formUnion(response.items.lazy.filter(\.isNsfw).map(\.id))
            safeItems = response.items.filter { !$0.isNsfw }
        }

        var seen = request.existingItemIDs
        let uniqueItems = safeItems.filter { seen.insert($0.id).inserted }
        let visibleServerTotal = max(0, response.totalCount - excludedNsfwIDs.count)

        return EntityGridPage(
            items: uniqueItems,
            nextCursor: response.nextCursor,
            totalCount: max(seen.count, visibleServerTotal),
            excludedNsfwIDs: excludedNsfwIDs
        )
    }
}
