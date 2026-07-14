public enum EntityDestinationPolicy {
    public static func style(
        for kind: EntityKind,
        on platform: EntityDestinationPlatform
    ) -> EntityDestinationStyle {
        style(for: kind, on: platform, intent: .detail)
    }

    public static func style(
        for kind: EntityKind,
        on platform: EntityDestinationPlatform,
        intent: EntityNavigationIntent
    ) -> EntityDestinationStyle {
        if intent == .metadata, kind == .image {
            return .standard
        }
        if intent == .audioCollection,
            kind == .collection,
            platform == .iOS || platform == .macOS
        {
            return .nativeAudioCollection
        }
        return switch (platform, kind) {
        case (.iOS, .audioLibrary), (.macOS, .audioLibrary):
            .nativeAlbum
        case (.iOS, .musicArtist), (.macOS, .musicArtist):
            .nativeArtist
        case (_, .image):
            .nativeImageViewer
        case (.tvOS, .videoSeries), (.tvOS, .videoSeason):
            .televisionSeasons
        default:
            .standard
        }
    }
}
