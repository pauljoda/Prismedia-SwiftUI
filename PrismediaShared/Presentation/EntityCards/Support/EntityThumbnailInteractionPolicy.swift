public struct EntityThumbnailInteractionPolicy: Hashable, Sendable {
    public let primaryIntent: EntityNavigationIntent
    public let primaryAccessibilityHint: String
    public let showsContextMenu: Bool
    public let detailActionLabel: String

    public init(item: EntityThumbnail, layout: EntityThumbnailLayout) {
        let startsPlayback =
            item.kind == .video
            && item.hasSourceMedia
            && item.thumbnailArtworkPresentation.isWide
            && layout.supportsDirectPlayback

        primaryIntent = startsPlayback ? .playback : .detail
        primaryAccessibilityHint = Self.accessibilityHint(
            startsPlayback: startsPlayback,
            resumeSeconds: item.resumeSeconds
        )
        #if os(tvOS)
            showsContextMenu = false
        #else
            showsContextMenu = startsPlayback
        #endif
        detailActionLabel = Self.detailActionLabel(parentKind: item.parentKind)
    }

    private static func accessibilityHint(
        startsPlayback: Bool,
        resumeSeconds: Double?
    ) -> String {
        guard startsPlayback else { return "Opens details" }
        guard let resumeSeconds, resumeSeconds > 0 else { return "Starts playback" }
        return "Resumes playback"
    }

    private static func detailActionLabel(parentKind: EntityKind?) -> String {
        switch parentKind {
        case .videoSeason, .videoSeries:
            "Go to Episode"
        default:
            "Go to Details"
        }
    }
}

extension EntityThumbnailLayout {
    fileprivate var supportsDirectPlayback: Bool {
        switch self {
        case .grid, .wall, .rail:
            true
        case .list, .feed, .mediaOnly:
            false
        }
    }
}
