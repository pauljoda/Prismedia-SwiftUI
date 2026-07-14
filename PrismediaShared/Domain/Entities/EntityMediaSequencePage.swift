import Foundation

public struct EntityMediaSequencePage: Equatable, Sendable {
    public let items: [EntityThumbnail]
    public let nextCursor: String?
    public let excludedNsfwIDs: Set<UUID>

    public init(
        items: [EntityThumbnail],
        nextCursor: String?,
        excludedNsfwIDs: Set<UUID> = []
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.excludedNsfwIDs = excludedNsfwIDs
    }
}
