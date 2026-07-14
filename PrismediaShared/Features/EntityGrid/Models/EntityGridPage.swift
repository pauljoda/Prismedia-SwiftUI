import Foundation

public struct EntityGridPage: Equatable, Sendable {
    let items: [EntityThumbnail]
    let nextCursor: String?
    let totalCount: Int
    let excludedNsfwIDs: Set<UUID>
}
