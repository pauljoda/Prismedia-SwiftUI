import Foundation

enum DashboardHeroAdvancePolicy {
    static func next(
        from current: DashboardHeroPosition,
        sceneCounts: [Int],
        reduceMotion: Bool
    ) -> DashboardHeroPosition {
        guard !reduceMotion, !sceneCounts.isEmpty else { return current }

        let itemIndex = min(max(current.itemIndex, 0), sceneCounts.count - 1)
        let sceneCount = max(sceneCounts[itemIndex], 1)
        let sceneIndex = min(max(current.sceneIndex, 0), sceneCount - 1)
        if sceneIndex + 1 < sceneCount {
            return DashboardHeroPosition(itemIndex: itemIndex, sceneIndex: sceneIndex + 1)
        }

        return DashboardHeroPosition(
            itemIndex: (itemIndex + 1) % sceneCounts.count,
            sceneIndex: 0
        )
    }
}
