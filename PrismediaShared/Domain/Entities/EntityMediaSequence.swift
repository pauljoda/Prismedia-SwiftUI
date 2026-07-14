import Foundation

public struct EntityMediaSequence: Hashable, Sendable {
    public let items: [EntityThumbnail]
    public let continuation: EntityMediaSequenceContinuation?

    public init(
        items: [EntityThumbnail],
        continuation: EntityMediaSequenceContinuation? = nil
    ) {
        var seen = Set<UUID>()
        self.items = items.filter { item in
            item.kind == .image && seen.insert(item.id).inserted
        }
        self.continuation = continuation?.including(itemIDs: Set(items.map(\.id)))
    }

    public var nextPageRequest: EntityMediaSequencePageRequest? {
        continuation?.pageRequest
    }

    public func index(of entityID: UUID) -> Int? {
        items.firstIndex { $0.id == entityID }
    }

    public func previous(to entityID: UUID) -> EntityThumbnail? {
        guard let index = index(of: entityID), index > items.startIndex else { return nil }
        return items[index - 1]
    }

    public func next(to entityID: UUID) -> EntityThumbnail? {
        guard let index = index(of: entityID), index < items.index(before: items.endIndex) else { return nil }
        return items[index + 1]
    }

    public func preloadItems(around entityID: UUID) -> [EntityThumbnail] {
        guard let index = index(of: entityID) else { return [] }
        var result = [items[index]]
        if index > items.startIndex {
            result.append(items[index - 1])
        }
        if index < items.index(before: items.endIndex) {
            result.append(items[index + 1])
        }
        return result
    }

    public func appending(
        _ page: EntityMediaSequencePage,
        nextCursor: String?
    ) -> EntityMediaSequence {
        let existingItemIDs = (continuation?.existingItemIDs ?? Set(items.map(\.id)))
            .union(page.items.map(\.id))
        let nextContinuation = continuation?.advancing(
            cursor: nextCursor,
            existingItemIDs: existingItemIDs,
            excludedNsfwIDs: page.excludedNsfwIDs
        )
        return EntityMediaSequence(
            items: items + page.items,
            continuation: nextContinuation
        )
    }
}
