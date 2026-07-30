import Foundation

public enum SearchHubKindCatalog {
    public static let kinds: [EntityKind] = [
        .movie,
        .videoSeries,
        .video,
        .person,
        .studio,
        .tag,
        .gallery,
        .book,
        .image,
        .collection,
        .audioLibrary,
        .audioTrack,
    ]

    public static var allKinds: Set<EntityKind> {
        Set(kinds)
    }

    public static func label(for kind: EntityKind) -> String {
        kind.groupLabel
    }

    public static func systemImage(for kind: EntityKind) -> String {
        kind.thumbnailFallbackSystemImage
    }
}
