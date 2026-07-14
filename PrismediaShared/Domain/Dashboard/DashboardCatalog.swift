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
        definition(.video, "Videos", "film", colorRole: .video, destinationID: "videos"),
        definition(.movie, "Movies", "movieclapper", colorRole: .movie, destinationID: "movies"),
        definition(.videoSeries, "Series", "rectangle.stack", colorRole: .series, destinationID: "series"),
        definition(.gallery, "Galleries", "photo.on.rectangle.angled", colorRole: .gallery, destinationID: "galleries"),
        definition(.book, "Books", "book", colorRole: .book, destinationID: "books"),
        definition(.image, "Images", "photo", colorRole: .image, destinationID: "images"),
        definition(.audioLibrary, "Albums", "waveform", colorRole: .audio, destinationID: "albums"),
        definition(
            .collection,
            "Collections",
            "square.stack.3d.up",
            colorRole: .collection,
            destinationID: "collections"
        ),
        definition(.person, "People", "person.2", colorRole: .people, destinationID: "people"),
        definition(.studio, "Studios", "building.2", colorRole: .studios, destinationID: "studios"),
        definition(.tag, "Tags", "tag", colorRole: .tags, destinationID: "tags"),
    ]

    public static func section(for kind: EntityKind) -> DashboardSectionDefinition? {
        sections.first { $0.kind == kind }
    }

    private static func definition(
        _ kind: EntityKind,
        _ title: String,
        _ systemImage: String,
        colorRole: DashboardSectionColorRole,
        destinationID: String
    ) -> DashboardSectionDefinition {
        DashboardSectionDefinition(
            kind: kind,
            title: title,
            systemImage: systemImage,
            colorRole: colorRole,
            destinationID: destinationID,
            query: EntityListQuery(kind: kind, sort: "added", sortDescending: true)
        )
    }
}
