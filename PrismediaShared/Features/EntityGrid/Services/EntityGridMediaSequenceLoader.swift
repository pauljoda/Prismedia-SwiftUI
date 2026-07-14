@MainActor
public struct EntityGridMediaSequenceLoader: EntityMediaSequenceLoading {
    private let service: EntityGridService

    public init(loader: any EntityGridLoading) {
        service = EntityGridService(loader: loader)
    }

    public func loadNextPage(
        _ request: EntityMediaSequencePageRequest
    ) async throws -> EntityMediaSequencePage {
        let page = try await service.loadNextVisiblePage(
            EntityGridPageRequest(
                generation: 0,
                query: request.query,
                pageSize: request.pageSize,
                search: request.search,
                cursor: request.cursor,
                preservingContent: true,
                existingItemIDs: request.existingItemIDs,
                excludedNsfwIDs: request.excludedNsfwIDs
            )
        )
        return EntityMediaSequencePage(
            items: page.items,
            nextCursor: page.nextCursor,
            excludedNsfwIDs: page.excludedNsfwIDs
        )
    }
}
