extension EntityThumbnail {
    /// Includes parent context so a playable video owned by a movie keeps the
    /// movie poster contract instead of changing shape between call sites.
    public var thumbnailArtworkPresentation: EntityThumbnailArtworkPresentation {
        EntityThumbnailArtworkPresentation(kind: thumbnailPresentationKind)
    }
}
