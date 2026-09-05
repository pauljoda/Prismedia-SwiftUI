import Foundation

/// Television is a playback catalog, not an acquisition or management surface.
/// Container availability is projected by the server from its structural descendants.
enum TVPlaybackCatalogPolicy {
    static let videoKinds: Set<EntityKind> = [.movie, .video, .videoEpisode, .videoSeason, .videoSeries]

    static func accepts(_ item: EntityThumbnail) -> Bool {
        item.hasSourceMedia && videoKinds.contains(item.kind)
    }
}
