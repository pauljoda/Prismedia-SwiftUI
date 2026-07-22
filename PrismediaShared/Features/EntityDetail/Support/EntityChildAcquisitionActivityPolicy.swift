import Foundation

enum EntityChildAcquisitionActivityPolicy {
    static func eligibleChildren(
        parentID: UUID,
        groups: [EntityGroup]
    ) -> [EntityThumbnail] {
        var seenIDs = Set<UUID>()
        return groups.flatMap(\.entities).filter { entity in
            entity.parentEntityID == parentID
                && requestableKinds.contains(entity.kind)
                && seenIDs.insert(entity.id).inserted
        }
    }

    static func orderedItems(
        _ items: [EntityChildAcquisitionActivityItem]
    ) -> [EntityChildAcquisitionActivityItem] {
        items
            .filter(\.hasActivity)
            .enumerated()
            .sorted { lhs, rhs in
                let lhsTier = tier(for: lhs.element)
                let rhsTier = tier(for: rhs.element)
                return lhsTier == rhsTier ? lhs.offset < rhs.offset : lhsTier < rhsTier
            }
            .map(\.element)
    }

    static func shouldPoll(_ items: [EntityChildAcquisitionActivityItem]) -> Bool {
        items.contains { item in
            item.isPreparingMetadata
                || RequestActivityStatusPolicy.shouldPoll(item.acquisition?.status)
        }
    }

    static func shouldAutoExpand(_ items: [EntityChildAcquisitionActivityItem]) -> Bool {
        items.contains { item in
            isAttentionRequired(item) || shouldPoll([item])
        }
    }

    static func isAttentionRequired(_ item: EntityChildAcquisitionActivityItem) -> Bool {
        guard let status = item.acquisition?.status.rawValue else { return false }
        return status == "awaiting-selection"
            || status == "failed"
            || status == "manual-import-required"
    }

    private static func tier(for item: EntityChildAcquisitionActivityItem) -> Int {
        if isAttentionRequired(item) { return 0 }
        if item.isPreparingMetadata
            || RequestActivityStatusPolicy.shouldPoll(item.acquisition?.status)
        {
            return 1
        }
        return 2
    }

    private static let requestableKinds: Set<EntityKind> = [
        .audioLibrary,
        .audioTrack,
        .book,
        .musicArtist,
        .bookAuthor,
        .movie,
        .video,
        .videoSeries,
        .videoSeason,
    ]
}
