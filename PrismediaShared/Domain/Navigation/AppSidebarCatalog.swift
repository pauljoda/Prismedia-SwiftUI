public enum AppSidebarCatalog {
    public static func sections(for user: UserAccount?) -> [AppSidebarSection] {
        var sections = publicSections
        #if os(iOS) || os(macOS)
            if user?.isAdmin == true {
                sections.append(operateSection)
            } else if user?.canCreateLibraries == true {
                sections.append(libraryManagementSection)
            }
        #endif
        return sections
    }

    private static let publicSections = [
        AppSidebarSection(
            id: "overview",
            title: "Overview",
            items: [
                item(in: ModeCatalog.overview, destinationID: "dashboard"),
                item(in: ModeCatalog.overview, destinationID: "favorites"),
                AppSidebarItem(
                    id: "search",
                    title: "Search",
                    systemImage: "magnifyingglass",
                    selection: .search
                ),
                item(in: ModeCatalog.overview, destinationID: "stats"),
            ]
        ),
        AppSidebarSection(
            id: "video",
            title: "Video",
            items: [
                item(in: ModeCatalog.video, destinationID: "movies"),
                item(in: ModeCatalog.video, destinationID: "series"),
                item(in: ModeCatalog.video, destinationID: "videos"),
            ]
        ),
        AppSidebarSection(
            id: "images",
            title: "Images",
            items: [
                item(in: ModeCatalog.images, destinationID: "galleries"),
                item(in: ModeCatalog.images, destinationID: "images"),
            ]
        ),
        AppSidebarSection(
            id: "audio",
            title: "Audio",
            items: [
                item(in: ModeCatalog.audio, destinationID: "artists"),
                item(in: ModeCatalog.audio, destinationID: "albums", title: "Audio"),
            ]
        ),
        AppSidebarSection(
            id: "books",
            title: "Books",
            items: [
                item(in: ModeCatalog.books, destinationID: "authors"),
                item(in: ModeCatalog.books, destinationID: "books"),
                item(in: ModeCatalog.books, destinationID: "comics"),
                item(in: ModeCatalog.books, destinationID: "ebooks"),
            ]
        ),
        AppSidebarSection(
            id: "browse",
            title: "Browse",
            items: [
                item(in: ModeCatalog.browse, destinationID: "people"),
                item(in: ModeCatalog.browse, destinationID: "studios"),
                item(in: ModeCatalog.browse, destinationID: "tags"),
                item(in: ModeCatalog.browse, destinationID: "collections"),
            ]
        ),
    ]

    #if os(iOS) || os(macOS)
        private static let operateSection = AppSidebarSection(
            id: "operate",
            title: "Operate",
            items: [
                item(in: ModeCatalog.manage, destinationID: "files"),
                item(in: ModeCatalog.manage, destinationID: "identify"),
                item(in: ModeCatalog.manage, destinationID: "request"),
                item(in: ModeCatalog.operate, destinationID: "plugins"),
                item(in: ModeCatalog.operate, destinationID: "jobs"),
                item(in: ModeCatalog.operate, destinationID: "settings"),
            ]
        )

        private static let libraryManagementSection = AppSidebarSection(
            id: "library-management",
            title: "Manage",
            items: [
                item(in: ModeCatalog.libraryManagement, destinationID: "settings")
            ]
        )
    #endif

    private static func item(
        in mode: AppMode,
        destinationID: String,
        title: String? = nil
    ) -> AppSidebarItem {
        guard let destination = mode.destination(id: destinationID) else {
            preconditionFailure("Unknown sidebar destination: \(destinationID)")
        }

        return AppSidebarItem(
            id: destination.id,
            title: title ?? destination.title,
            systemImage: destination.systemImage,
            selection: .destination(modeID: mode.id, destinationID: destination.id)
        )
    }
}
