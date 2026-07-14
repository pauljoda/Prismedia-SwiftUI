import Foundation

public struct EntityMediaSequenceContinuation: Hashable, Sendable {
    public let query: EntityListQuery
    public let pageSize: Int
    public let search: String?
    public let cursor: String
    public let existingItemIDs: Set<UUID>
    public let excludedNsfwIDs: Set<UUID>

    public init(
        query: EntityListQuery,
        pageSize: Int,
        search: String?,
        cursor: String,
        existingItemIDs: Set<UUID>,
        excludedNsfwIDs: Set<UUID>
    ) {
        precondition(pageSize > 0, "A media sequence page size must be positive.")
        precondition(!cursor.isEmpty, "A media sequence continuation cursor must not be empty.")
        self.query = query
        self.pageSize = pageSize
        let normalizedSearch = search?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.search = normalizedSearch?.isEmpty == false ? normalizedSearch : nil
        self.cursor = cursor
        self.existingItemIDs = existingItemIDs
        self.excludedNsfwIDs = excludedNsfwIDs
    }

    public var pageRequest: EntityMediaSequencePageRequest {
        EntityMediaSequencePageRequest(
            query: query,
            pageSize: pageSize,
            search: search,
            cursor: cursor,
            existingItemIDs: existingItemIDs,
            excludedNsfwIDs: excludedNsfwIDs
        )
    }

    func including(itemIDs: Set<UUID>) -> EntityMediaSequenceContinuation {
        EntityMediaSequenceContinuation(
            query: query,
            pageSize: pageSize,
            search: search,
            cursor: cursor,
            existingItemIDs: existingItemIDs.union(itemIDs),
            excludedNsfwIDs: excludedNsfwIDs
        )
    }

    func advancing(
        cursor: String?,
        existingItemIDs: Set<UUID>,
        excludedNsfwIDs: Set<UUID>
    ) -> EntityMediaSequenceContinuation? {
        guard let cursor, !cursor.isEmpty else { return nil }
        return EntityMediaSequenceContinuation(
            query: query,
            pageSize: pageSize,
            search: search,
            cursor: cursor,
            existingItemIDs: existingItemIDs,
            excludedNsfwIDs: excludedNsfwIDs
        )
    }
}
