import Foundation

enum EntityFailedParentAcquisitionPolicy {
    static func activeChildren(
        parentID: UUID,
        groups: [EntityGroup]
    ) -> [EntityThumbnail] {
        EntityChildAcquisitionActivityPolicy.eligibleChildren(
            parentID: parentID,
            groups: groups
        )
        .filter { child in
            [child.wantedStatus, child.latestAcquisitionStatus]
                .compactMap { $0 }
                .contains(where: RequestActivityStatusPolicy.shouldPoll)
        }
    }

    static func shouldDemoteParent(
        status: AcquisitionStatus?,
        activeChildren: [EntityThumbnail]
    ) -> Bool {
        status?.rawValue == "failed" && !activeChildren.isEmpty
    }

    static func activeSummary(
        activeChildren: [EntityThumbnail],
        eligibleChildren: [EntityThumbnail]
    ) -> String {
        let count = activeChildren.count
        return "\(count) \(childNoun(count: count, children: eligibleChildren)) active instead"
    }

    static func accessibilityEntryMessage(
        activeChildren: [EntityThumbnail],
        eligibleChildren: [EntityThumbnail]
    ) -> String {
        "Parent release attempt failed. \(activeSummary(activeChildren: activeChildren, eligibleChildren: eligibleChildren))."
    }

    static let accessibilityCompletionMessage =
        "Active child acquisitions finished. The parent release attempt still needs attention."

    private static func childNoun(
        count: Int,
        children: [EntityThumbnail]
    ) -> String {
        if !children.isEmpty, children.allSatisfy({ $0.kind == .video }) {
            return count == 1 ? "episode" : "episodes"
        }
        if !children.isEmpty, children.allSatisfy({ $0.kind == .audioTrack }) {
            return count == 1 ? "track" : "tracks"
        }
        return count == 1 ? "child item" : "child items"
    }
}
