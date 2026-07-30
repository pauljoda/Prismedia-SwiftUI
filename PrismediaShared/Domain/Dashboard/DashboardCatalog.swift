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
        definition(.video),
        definition(.movie),
        definition(.videoSeries),
        definition(.gallery),
        definition(.book),
        definition(.image),
        definition(.audioLibrary),
        definition(.collection),
        definition(.person),
        definition(.studio),
        definition(.tag),
    ]

    public static func section(for kind: EntityKind) -> DashboardSectionDefinition? {
        sections.first { $0.kind == kind }
    }

    private static func definition(_ kind: EntityKind) -> DashboardSectionDefinition {
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
            systemImage: kind == .audioLibrary ? "waveform" : target.destination.systemImage,
            colorRole: .entity(kind),
            destinationID: target.destination.id,
            query: query
        )
    }
}
