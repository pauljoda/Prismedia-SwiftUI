import Foundation

public enum DashboardCatalog {
    public static let itemLimit = 20
    public static let continueQuery = EntityListQuery(
        sort: "last-played",
        sortDescending: true,
        status: "in-progress"
    )
    public static let recentQuery = EntityListQuery(
        sort: "last-played",
        sortDescending: true,
        status: "watched"
    )

    public static let sections: [DashboardSectionDefinition] = [
        definition(.video, colorRole: .video),
        definition(.movie, colorRole: .movie),
        definition(.videoSeries, colorRole: .series),
        definition(.gallery, colorRole: .gallery),
        definition(.book, colorRole: .book),
        definition(.image, colorRole: .image),
        definition(.audioLibrary, systemImage: "waveform", colorRole: .audio),
        definition(.collection, colorRole: .collection),
        definition(.person, colorRole: .people),
        definition(.studio, colorRole: .studios),
        definition(.tag, colorRole: .tags),
    ]

    public static func section(for kind: EntityKind) -> DashboardSectionDefinition? {
        sections.first { $0.kind == kind }
    }

    private static func definition(
        _ kind: EntityKind,
        systemImage: String? = nil,
        colorRole: DashboardSectionColorRole
    ) -> DashboardSectionDefinition {
        guard
            let target = ModeCatalog.canonicalDestination(for: kind),
            case .entityList(let entityList) = target.destination.content
        else {
            preconditionFailure("Dashboard kind \(kind.rawValue) requires a canonical entity destination.")
        }
        var query = entityList.query
        query.sortDescending = true

        return DashboardSectionDefinition(
            kind: kind,
            title: target.destination.title,
            systemImage: systemImage ?? target.destination.systemImage,
            colorRole: colorRole,
            destinationID: target.destination.id,
            query: query
        )
    }
}
