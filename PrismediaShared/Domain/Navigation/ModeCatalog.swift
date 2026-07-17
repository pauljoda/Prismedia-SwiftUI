import Foundation

/// Native app-shell catalog. This mirrors the web app's broad navigation while
/// allowing the compact iOS rail to adapt to the active section.
public enum ModeCatalog {
    public static let overview = AppMode(
        id: "overview",
        title: "Overview",
        systemImage: "house",
        destinations: [
            destination("dashboard", "Dashboard", "rectangle.3.group", content: .dashboard),
            entityDestination("overview-collections", "Collections", "square.stack.3d.up", kind: .collection),
            destination("stats", "Stats", "chart.line.uptrend.xyaxis", content: .playbackStatistics),
        ]
    )

    public static let video = AppMode(
        id: "video",
        title: "Video",
        systemImage: "play.rectangle",
        destinations: [
            entityDestination("videos", "Videos", "film", kind: .video),
            entityDestination("movies", "Movies", "movieclapper", kind: .movie),
            entityDestination("series", "Series", "rectangle.stack", kind: .videoSeries),
        ]
    )

    public static let images = AppMode(
        id: "images",
        title: "Images",
        systemImage: "photo.stack",
        destinations: [
            entityDestination("images", "Images", "photo", kind: .image),
            entityDestination("galleries", "Galleries", "photo.on.rectangle.angled", kind: .gallery),
        ]
    )

    public static let audio = AppMode(
        id: "audio",
        title: "Audio",
        systemImage: "waveform",
        destinations: [
            entityDestination("albums", "Albums", "square.stack", kind: .audioLibrary),
            entityDestination("artists", "Artists", "music.mic", kind: .musicArtist),
            entityDestination("tracks", "Tracks", "music.note.list", kind: .audioTrack),
            entityDestination(
                "audio-collections", "Collections", "rectangle.stack.badge.play", kind: .collection),
        ]
    )

    public static let books = AppMode(
        id: "books",
        title: "Books",
        systemImage: "books.vertical",
        destinations: [
            entityDestination("books", "Books", "book", kind: .book),
            entityDestination("authors", "Authors", "signature", kind: .bookAuthor),
            entityDestination(
                "comics",
                "Comics",
                "book.pages",
                query: EntityListQuery(kind: .book, sort: "added", bookType: "comic,manga")
            ),
            entityDestination(
                "ebooks",
                "eBooks",
                "book.closed",
                query: EntityListQuery(
                    kind: .book,
                    sort: "added",
                    bookType: "book,novel",
                    bookFormat: "epub,pdf"
                )
            ),
        ]
    )

    public static let browse = AppMode(
        id: "browse",
        title: "Browse",
        systemImage: "square.grid.2x2",
        destinations: [
            entityDestination(
                "collections",
                "Collections",
                "square.stack.3d.up",
                query: EntityListQuery(kind: .collection, sort: "added")
            ),
            entityDestination("people", "People", "person.2", kind: .person),
            entityDestination("studios", "Studios", "building.2", kind: .studio),
            entityDestination("tags", "Tags", "tag", kind: .tag),
        ]
    )

    #if os(iOS) || os(macOS)
        public static let manage = AppMode(
            id: "manage",
            title: "Manage",
            systemImage: "square.and.pencil",
            requiresAdmin: true,
            destinations: [
                manageDestination(.files, "Files", "folder.badge.gearshape"),
                manageDestination(.identify, "Identify", "doc.viewfinder"),
                manageDestination(.request, "Request", "paperplane"),
            ],
            preferredTabDestinationIDs: ["files", "identify", "request"]
        )
    #endif

    public static let operate = AppMode(
        id: "operate",
        title: "Operate",
        systemImage: "wrench.and.screwdriver",
        requiresAdmin: true,
        destinations: [
            administrativeDestination(.plugins, "Plugins", "puzzlepiece.extension"),
            administrativeDestination(.jobs, "Jobs", "waveform.path.ecg"),
            administrativeDestination(.settings, "Settings", "gearshape"),
        ],
        preferredTabDestinationIDs: ["plugins", "jobs", "settings"]
    )

    #if os(iOS) || os(macOS)
        public static let libraryManagement = AppMode(
            id: "library-management",
            title: "Settings",
            systemImage: "folder.badge.gearshape",
            destinations: [
                administrativeDestination(.settings, "Settings", "gearshape")
            ]
        )
    #endif

    #if os(tvOS)
        public static let all: [AppMode] = [overview, video, images, audio, books, browse, operate]
    #else
        public static let all: [AppMode] = [overview, video, images, audio, books, browse, manage, operate]
    #endif

    public static func modes(for user: UserAccount?) -> [AppMode] {
        var modes = all.filter { !$0.requiresAdmin || user?.isAdmin == true }
        #if os(iOS) || os(macOS)
            if user?.isAdmin != true, user?.canCreateLibraries == true {
                modes.append(libraryManagement)
            }
        #endif
        return modes
    }

    public static func mode(containing destinationID: String) -> AppMode? {
        all.first { $0.destination(id: destinationID) != nil }
    }

    public static func canonicalDestination(
        for entityKind: EntityKind
    ) -> (mode: AppMode, destination: AppDestination)? {
        let destinationID: String
        switch entityKind {
        case .video: destinationID = "videos"
        case .movie: destinationID = "movies"
        case .videoSeries, .videoSeason: destinationID = "series"
        case .image: destinationID = "images"
        case .gallery: destinationID = "galleries"
        case .audioLibrary: destinationID = "albums"
        case .musicArtist: destinationID = "artists"
        case .audioTrack: destinationID = "tracks"
        case .book, .bookChapter, .bookPage: destinationID = "books"
        case .bookAuthor: destinationID = "authors"
        case .collection: destinationID = "collections"
        case .person: destinationID = "people"
        case .studio: destinationID = "studios"
        case .tag: destinationID = "tags"
        default: return nil
        }

        guard
            let mode = mode(containing: destinationID),
            let destination = mode.destination(id: destinationID)
        else {
            return nil
        }
        return (mode, destination)
    }

    private static func destination(
        _ id: String,
        _ title: String,
        _ systemImage: String,
        content: AppDestinationContent
    ) -> AppDestination {
        AppDestination(id: id, title: title, systemImage: systemImage, content: content)
    }

    private static func entityDestination(
        _ id: String,
        _ title: String,
        _ systemImage: String,
        kind: EntityKind
    ) -> AppDestination {
        let sort =
            kind == .person || kind == .studio || kind == .tag
            ? "references"
            : "added"
        return entityDestination(
            id,
            title,
            systemImage,
            query: EntityListQuery(kind: kind, sort: sort)
        )
    }

    private static func entityDestination(
        _ id: String,
        _ title: String,
        _ systemImage: String,
        query: EntityListQuery
    ) -> AppDestination {
        AppDestination(
            id: id,
            title: title,
            systemImage: systemImage,
            content: .entityList(EntityListDestination(query: query))
        )
    }

    private static func administrativeDestination(
        _ administration: AdministrativeDestination,
        _ title: String,
        _ systemImage: String
    ) -> AppDestination {
        AppDestination(
            id: administration.rawValue,
            title: title,
            systemImage: systemImage,
            content: .administration(administration)
        )
    }

    #if os(iOS) || os(macOS)
        private static func manageDestination(
            _ manage: ManageDestination,
            _ title: String,
            _ systemImage: String
        ) -> AppDestination {
            AppDestination(
                id: manage.rawValue,
                title: title,
                systemImage: systemImage,
                content: .manage(manage)
            )
        }
    #endif
}
