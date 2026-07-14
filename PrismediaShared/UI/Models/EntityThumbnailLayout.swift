public enum EntityThumbnailLayout: Hashable, Sendable {
    case wall
    case grid
    case list
    case rail
    case feed
    case mediaOnly

    public func artworkAspectRatio(
        for presentation: EntityThumbnailArtworkPresentation
    ) -> Double {
        presentation.aspectRatio
    }
}
