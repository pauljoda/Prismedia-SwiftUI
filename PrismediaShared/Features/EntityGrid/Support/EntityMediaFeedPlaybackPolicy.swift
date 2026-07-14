import Foundation

public struct EntityMediaFeedPlaybackPolicy: Sendable {
    public static func playbackID(
        orderedIDs: [UUID],
        visibleIDs: Set<UUID>
    ) -> UUID? {
        orderedIDs.first(where: visibleIDs.contains)
    }

    public static func prewarmIDs(
        orderedIDs: [UUID],
        visibleIDs: Set<UUID>,
        eligibleIDs: Set<UUID>,
        aheadCount: Int = 2
    ) -> Set<UUID> {
        guard !orderedIDs.isEmpty, !eligibleIDs.isEmpty, aheadCount >= 0 else { return [] }

        let anchorID = playbackID(orderedIDs: orderedIDs, visibleIDs: visibleIDs)
        let anchorIndex = anchorID.flatMap(orderedIDs.firstIndex(of:)) ?? orderedIDs.startIndex
        var result = Set<UUID>()
        if let anchorID, eligibleIDs.contains(anchorID) {
            result.insert(anchorID)
        }
        let targetCount = result.count + aheadCount

        let firstAheadIndex = anchorID == nil ? anchorIndex : anchorIndex + 1
        guard firstAheadIndex < orderedIDs.endIndex, aheadCount > 0 else { return result }
        for itemID in orderedIDs[firstAheadIndex...] where eligibleIDs.contains(itemID) {
            result.insert(itemID)
            if result.count == targetCount { break }
        }
        return result
    }
}
