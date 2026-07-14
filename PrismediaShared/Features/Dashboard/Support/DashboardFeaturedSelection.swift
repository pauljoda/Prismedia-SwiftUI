import Foundation

enum DashboardFeaturedSelection {
    static func items(
        playbackHistory: [EntityThumbnail],
        catalogSources: [[EntityThumbnail]],
        limit: Int = 6
    ) -> [EntityThumbnail] {
        guard limit > 0 else { return [] }

        var seen = Set<UUID>()
        return Array(
            (playbackHistory.filter(isVideoKind)
                + catalogSources.joined().filter(isExplicitlyPlayableVideo))
                .filter { seen.insert($0.id).inserted }
                .prefix(limit)
        )
    }

    private static func isVideoKind(_ item: EntityThumbnail) -> Bool {
        item.kind == .video || item.kind == .movie
    }

    private static func isExplicitlyPlayableVideo(_ item: EntityThumbnail) -> Bool {
        guard item.kind == .video || item.kind == .movie else { return false }
        if item.hasSourceMedia { return true }
        return item.kind == .movie
            && item.referenceCounts.contains { $0.kind == .video && $0.count > 0 }
    }
}
