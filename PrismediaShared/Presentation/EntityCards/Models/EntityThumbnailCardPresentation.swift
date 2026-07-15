public struct EntityThumbnailCardPresentation: Hashable, Sendable {
    public static let extendedLandscapeAspectRatio = 6.0 / 5.0

    public let usesArtworkExtension: Bool
    public let showsTitleOverlay: Bool
    public let showsArtworkBadges: Bool
    public let cardAspectRatio: Double

    public init(item: EntityThumbnail, layout: EntityThumbnailLayout) {
        let artwork = item.thumbnailArtworkPresentation
        usesArtworkExtension = artwork.isWide && layout.supportsArtworkExtension
        showsTitleOverlay =
            !usesArtworkExtension
            && (item.bestCoverPath == nil || Self.alwaysIdentifiesWithTitle(item.kind))
        showsArtworkBadges = true
        cardAspectRatio =
            usesArtworkExtension
            ? Self.extendedLandscapeAspectRatio
            : artwork.aspectRatio
    }

    public func width(forCardHeight height: Double) -> Double {
        height * cardAspectRatio
    }

    private static func alwaysIdentifiesWithTitle(_ kind: EntityKind) -> Bool {
        kind == .person
            || kind == .studio
            || kind == .tag
            || kind == .collection
    }
}

extension EntityThumbnailLayout {
    fileprivate var supportsArtworkExtension: Bool {
        switch self {
        case .grid, .wall, .rail:
            true
        case .list, .feed, .mediaOnly:
            false
        }
    }
}
