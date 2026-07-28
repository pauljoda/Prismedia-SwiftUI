public enum EntityThumbnailLayout: Hashable, Sendable {
    case wall
    case grid
    case list
    case rail
    case feed
    case mediaOnly
    case compact

    public func artworkAspectRatio(
        for presentation: EntityThumbnailArtworkPresentation
    ) -> Double {
        presentation.aspectRatio
    }
}
