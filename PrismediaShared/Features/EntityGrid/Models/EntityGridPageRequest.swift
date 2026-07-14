import Foundation

public struct EntityGridPageRequest: Sendable {
    let generation: Int
    let query: EntityListQuery
    let pageSize: Int
    let search: String?
    let cursor: String?
    let preservingContent: Bool
    let existingItemIDs: Set<UUID>
    let excludedNsfwIDs: Set<UUID>
}
