import Foundation

public struct EntityMediaSequencePageRequest: Hashable, Sendable {
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
        self.query = query
        self.pageSize = pageSize
        self.search = search
        self.cursor = cursor
        self.existingItemIDs = existingItemIDs
        self.excludedNsfwIDs = excludedNsfwIDs
    }
}
