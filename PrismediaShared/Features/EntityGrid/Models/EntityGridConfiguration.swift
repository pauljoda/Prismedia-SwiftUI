import Foundation

public struct EntityGridConfiguration: Hashable, Sendable {
    public let title: String
    public let query: EntityListQuery
    public let defaultFilters: EntityGridFilters
    public let supportsSearch: Bool
    public let pageSize: Int
    public let minimumColumnWidth: CGFloat
    public let preferencesID: String
    public let defaultDisplayMode: EntityGridDisplayMode
    public let availableDisplayModes: [EntityGridDisplayMode]
    public let emptyTitle: String
    public let emptyDescription: String

    public init(
        title: String,
        query: EntityListQuery,
        defaultFilters: EntityGridFilters = EntityGridFilters(),
        supportsSearch: Bool = false,
        pageSize: Int = 48,
        minimumColumnWidth: CGFloat = 150,
        defaultDisplayMode: EntityGridDisplayMode = .grid,
        availableDisplayModes: [EntityGridDisplayMode] = EntityGridDisplayMode.allCases,
        emptyTitle: String? = nil,
        emptyDescription: String = "Items will appear here when they’re added to your library.",
        preferencesID: String? = nil
    ) {
        precondition(pageSize > 0, "An entity grid page size must be positive.")
        precondition(minimumColumnWidth > 0, "An entity grid column width must be positive.")
        precondition(!availableDisplayModes.isEmpty, "An entity grid must support at least one display mode.")
        precondition(
            availableDisplayModes.contains(defaultDisplayMode),
            "The default entity grid display mode must be available."
        )

        self.title = title
        self.query = query
        self.defaultFilters = defaultFilters
        self.supportsSearch = supportsSearch
        self.pageSize = pageSize
        self.minimumColumnWidth = minimumColumnWidth
        self.defaultDisplayMode = defaultDisplayMode
        self.availableDisplayModes = availableDisplayModes
        self.emptyTitle = emptyTitle ?? "No \(title)"
        self.emptyDescription = emptyDescription
        self.preferencesID = preferencesID ?? Self.defaultPreferencesID(title: title, query: query)
    }

    func resolvedDisplayMode(restoring restoredDisplayMode: EntityGridDisplayMode?) -> EntityGridDisplayMode {
        guard let restoredDisplayMode, availableDisplayModes.contains(restoredDisplayMode) else {
            return defaultDisplayMode
        }
        return restoredDisplayMode
    }

    func defaultControls() -> EntityGridControls {
        var controls = EntityGridControls(baselineQuery: query)
        controls.filters = defaultFilters
        return controls
    }

    private static func defaultPreferencesID(title: String, query: EntityListQuery) -> String {
        let kind = query.kind?.rawValue ?? query.kinds.map(\.rawValue).joined(separator: ",")
        let routeConstraints = [query.bookType, query.bookFormat]
            .compactMap { $0 }
            .joined(separator: ":")
        return [title.lowercased(), kind, routeConstraints]
            .filter { !$0.isEmpty }
            .joined(separator: ":")
    }
}

extension EntityGridConfiguration {
    public static func library(
        destinationID: String,
        title: String,
        query: EntityListQuery,
        supportsSearch: Bool = true,
        minimumColumnWidth: CGFloat = 150,
        preferencesID: String? = nil
    ) -> EntityGridConfiguration {
        let presentation = routePresentation(destinationID: destinationID, title: title)
        return EntityGridConfiguration(
            title: title,
            query: query,
            supportsSearch: supportsSearch,
            minimumColumnWidth: minimumColumnWidth,
            defaultDisplayMode: presentation.defaultMode,
            availableDisplayModes: presentation.availableModes,
            emptyTitle: presentation.emptyTitle,
            emptyDescription: presentation.emptyDescription,
            preferencesID: preferencesID
        )
    }

    private static func routePresentation(
        destinationID: String,
        title: String
    ) -> (
        defaultMode: EntityGridDisplayMode,
        availableModes: [EntityGridDisplayMode],
        emptyTitle: String,
        emptyDescription: String
    ) {
        switch destinationID {
        case "images":
            return (
                .wall, [.wall, .grid, .list, .feed], "No Images",
                "No images are in your library yet. Add a library root and scan to get started."
            )
        case "galleries":
            return (
                .grid, [.grid, .list, .feed], "No Galleries",
                "No galleries are in your library yet. Add a library root and scan to get started."
            )
        case "videos":
            return (
                .wall, [.wall, .grid, .list, .feed], "No Videos",
                "No videos are in your library yet. Add a library root and scan to get started."
            )
        case "movies":
            return (
                .grid, [.grid, .list], "No Movies",
                "No movies are in your library yet. Add a same-named movie folder and scan to get started."
            )
        case "series":
            return (
                .grid, [.grid, .list], "No Series",
                "No series are in your library yet. Add a library root and scan to get started."
            )
        case "books":
            return (
                .grid, [.grid, .list], "No Books",
                "No books are in your library yet. Add a library root and scan to get started."
            )
        case "comics":
            return (
                .grid, [.grid, .list], "No Comics",
                "No comics are in your library yet. Add a library root with comic or manga files and scan to get started."
            )
        case "ebooks":
            return (
                .grid, [.grid, .list], "No eBooks",
                "No eBooks are in your library yet. Add a library root with EPUB or PDF files and scan to get started."
            )
        case "collections", "overview-collections", "audio-collections":
            return (
                .grid, [.grid, .list], "No Collections",
                "No collections exist yet. Create one to group media across your library."
            )
        case "people":
            return (.grid, [.grid, .list], "No People", "People appear as media gains credit metadata.")
        case "studios":
            return (.grid, [.grid, .list], "No Studios", "Studios appear as media gains studio metadata.")
        case "tags":
            return (.grid, [.grid, .list], "No Tags", "Tags appear as media is tagged.")
        case "artists":
            return (
                .grid, [.grid, .list], "No Artists",
                "Organize music as Artist/Album/Songs and scan to group albums under an artist."
            )
        case "albums":
            return (
                .grid, [.grid, .list], "No Albums",
                "No albums are in your library yet. Add a library root and scan to get started."
            )
        case "tracks":
            return (.list, [.list], "No Tracks", "Tracks appear after audio libraries are scanned.")
        case "authors":
            return (
                .grid, [.grid, .list], "No Authors",
                "Organize books as Author/Title and scan to group them under an author."
            )
        default:
            return (.grid, [.grid, .list], "No \(title)", "Items will appear here when they’re added to your library.")
        }
    }
}
