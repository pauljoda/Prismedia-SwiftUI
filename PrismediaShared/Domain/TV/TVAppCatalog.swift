import Foundation

public enum TVAppCatalog {
    public static let tabs = [
        TVAppTab(id: "home", title: "Home", systemImage: "house"),
        TVAppTab(
            id: "movies",
            title: "Movies",
            systemImage: "movieclapper",
            query: EntityListQuery(kind: .movie, sort: "added")
        ),
        TVAppTab(
            id: "series",
            title: "Series",
            systemImage: "rectangle.stack",
            query: EntityListQuery(kind: .videoSeries, sort: "added")
        ),
        TVAppTab(
            id: "collections",
            title: "Collections",
            systemImage: "square.stack.3d.up",
            query: EntityListQuery(kind: .collection, sort: "added")
        ),
        TVAppTab(
            id: "search",
            title: "Search",
            systemImage: "magnifyingglass",
            query: EntityListQuery(
                kinds: [.movie, .videoSeries, .collection],
                sort: "added"
            )
        ),
        TVAppTab(
            id: "account",
            title: "Settings",
            systemImage: "gearshape"
        ),
    ]

    public static let homeShelves = [
        TVHomeShelf(
            id: "in-progress",
            title: "Continue Watching",
            systemImage: "play.circle",
            query: EntityListQuery(
                kinds: [.movie, .video, .videoSeries, .videoSeason],
                sort: "last-played",
                status: "in-progress"
            ),
            limit: 20
        ),
        TVHomeShelf(
            id: "recently-watched",
            title: "Recently Watched",
            systemImage: "clock.arrow.circlepath",
            query: EntityListQuery(
                kinds: [.movie, .video, .videoSeries, .videoSeason],
                sort: "last-played",
                status: "watched"
            ),
            limit: 20
        ),
        TVHomeShelf(
            id: "movies",
            title: "Recently Added Movies",
            systemImage: "movieclapper",
            query: EntityListQuery(kind: .movie, sort: "added"),
            limit: 20,
            destinationTabID: "movies"
        ),
        TVHomeShelf(
            id: "series",
            title: "Recently Added Series",
            systemImage: "rectangle.stack",
            query: EntityListQuery(kind: .videoSeries, sort: "added"),
            limit: 20,
            destinationTabID: "series"
        ),
    ]
}
