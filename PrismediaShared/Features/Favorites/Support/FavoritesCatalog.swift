import Foundation

public enum FavoritesCatalog {
    public static let itemLimit = DashboardCatalog.itemLimit
    public static let kinds: [EntityKind] = [
        .video,
        .movie,
        .videoSeries,
        .gallery,
        .image,
        .audioLibrary,
        .musicArtist,
        .audioTrack,
        .book,
        .bookAuthor,
        .collection,
        .person,
        .studio,
        .tag,
    ]

    public static let sections: [FavoritesSectionDefinition] = kinds.map(definition)

    private static func definition(for kind: EntityKind) -> FavoritesSectionDefinition {
        guard
            let target = ModeCatalog.canonicalDestination(for: kind),
            case .entityList(let entityList) = target.destination.content
        else {
            preconditionFailure("Favorite kind \(kind.rawValue) requires a canonical entity destination.")
        }

        var query = entityList.query
        query.kind = kind
        query.kinds = []
        query.sort = EntityGridSort.lastAccessed.rawValue
        query.sortDescending = true
        query.favorite = true

        return FavoritesSectionDefinition(
            kind: kind,
            title: target.destination.title,
            systemImage: kind == .audioLibrary ? "waveform" : target.destination.systemImage,
            colorRole: DashboardSectionColorRole.role(for: kind),
            destinationID: target.destination.id,
            query: query
        )
    }
}
