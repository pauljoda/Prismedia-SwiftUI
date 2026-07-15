import SwiftUI

/// One system-owned adaptive app shell. Compact iOS uses feature tabs, while
/// regular-width iOS and macOS expose the full sectioned destination sidebar.
public struct PrismediaShellView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(PrismediaAppRouter.self) private var router
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    public init() {}

    public var body: some View {
        Group {
            if let user = environment.session?.user, let client = environment.client {
                #if os(iOS)
                    iOSShell(user: user, client: client)
                #elseif os(tvOS)
                    PrismediaTVShellView(user: user, client: client)
                #elseif os(macOS)
                    macOSShell(user: user, client: client)
                #endif
            }
        }
        .onAppear { router.reconcile(with: availableModes) }
        .onChange(of: availableModes) { _, _ in
            router.reconcile(with: availableModes)
        }
    }

    private func tabView(
        user: UserAccount,
        client: PrismediaAPIClient,
        videoPlaybackSession: VideoPlaybackSession
    ) -> some View {
        let detailDependencies = PrismediaEntityDetailComposition.dependencies(
            client: client,
            userID: user.id,
            isAdministrator: user.isAdmin,
            onEntityMutated: { environment.entityDidMutate() }
        )

        return TabView(selection: tabSelection(videoPlaybackSession: videoPlaybackSession)) {
            ForEach(activeTabDestinations) { destination in
                Tab(
                    destination.title,
                    systemImage: destination.systemImage,
                    value: PrismediaTabSelection.destination(destination.id)
                ) {
                    destinationContent(
                        destination,
                        client: client,
                        detailDependencies: detailDependencies,
                        videoPlaybackSession: videoPlaybackSession
                    )
                }
            }

            Tab(
                "Browse",
                systemImage: "square.grid.2x2",
                value: PrismediaTabSelection.search,
                role: .search
            ) {
                searchContent(
                    user: user,
                    client: client,
                    detailDependencies: detailDependencies,
                    videoPlaybackSession: videoPlaybackSession
                )
            }
        }
        .id("content-visibility-\(environment.allowsNsfwContent)")
        .prismediaAdaptiveAppTabStyle()
        .onAppear {
            router.onWillOpenEntity = {
                videoPlaybackSession.inlinePlaybackWillNavigate()
            }
        }
        .onDisappear {
            router.onWillOpenEntity = nil
        }
    }

    private func wideShell(
        user: UserAccount,
        client: PrismediaAPIClient,
        videoPlaybackSession: VideoPlaybackSession
    ) -> some View {
        let detailDependencies = PrismediaEntityDetailComposition.dependencies(
            client: client,
            userID: user.id,
            isAdministrator: user.isAdmin,
            onEntityMutated: { environment.entityDidMutate() }
        )

        return NavigationSplitView {
            PrismediaSidebarView(
                sections: AppSidebarCatalog.sections(for: user),
                selection: sidebarSelection(videoPlaybackSession: videoPlaybackSession)
            )
        } detail: {
            wideDetail(
                user: user,
                client: client,
                detailDependencies: detailDependencies,
                videoPlaybackSession: videoPlaybackSession
            )
        }
        .navigationSplitViewStyle(.balanced)
        .id("content-visibility-\(environment.allowsNsfwContent)")
        .onAppear {
            router.onWillOpenEntity = {
                videoPlaybackSession.inlinePlaybackWillNavigate()
            }
        }
        .onDisappear {
            router.onWillOpenEntity = nil
        }
    }

    @ViewBuilder
    private func wideDetail(
        user: UserAccount,
        client: PrismediaAPIClient,
        detailDependencies: EntityDetailDependencies,
        videoPlaybackSession: VideoPlaybackSession
    ) -> some View {
        switch router.selectedTab {
        case .search:
            searchContent(
                user: user,
                client: client,
                detailDependencies: detailDependencies,
                videoPlaybackSession: videoPlaybackSession
            )

        case .destination(let destinationID):
            if let destination = selectedDestination(id: destinationID) {
                destinationContent(
                    destination,
                    client: client,
                    detailDependencies: detailDependencies,
                    videoPlaybackSession: videoPlaybackSession
                )
            } else {
                ContentUnavailableView("Page Unavailable", systemImage: "rectangle.slash")
            }
        }
    }

    private func searchContent(
        user: UserAccount,
        client: PrismediaAPIClient,
        detailDependencies: EntityDetailDependencies,
        videoPlaybackSession: VideoPlaybackSession
    ) -> some View {
        @Bindable var router = router

        return SearchHubView(
            loader: PrismediaSearchHubLoader(client: client),
            detailDependencies: detailDependencies,
            searchText: $router.searchText,
            navigationPath: pathBinding(
                for: PrismediaAppRouter.searchPathID,
                videoPlaybackSession: videoPlaybackSession
            ),
            user: user,
            modes: availableModes,
            allowsNsfwContent: environment.allowsNsfwContent,
            onSelectMode: { mode in
                videoPlaybackSession.inlinePlaybackWillNavigate()
                router.select(mode: mode)
            },
            onSelectDestination: { mode, destination in
                videoPlaybackSession.inlinePlaybackWillNavigate()
                router.select(mode: mode, destination: destination)
            },
            onSetAllowsNsfwContent: environment.setAllowsNsfwContent,
            onSignOut: {
                Task { await environment.signOut() }
            }
        )
        .id("search-\(environment.allowsNsfwContent)")
    }

    @ViewBuilder
    private func destinationContent(
        _ destination: AppDestination,
        client: PrismediaAPIClient,
        detailDependencies: EntityDetailDependencies,
        videoPlaybackSession: VideoPlaybackSession
    ) -> some View {
        switch destination.content {
        case .dashboard:
            DashboardView(
                loader: PrismediaDashboardLoader(client: client),
                detailDependencies: detailDependencies,
                navigationPath: pathBinding(
                    for: destination.id,
                    videoPlaybackSession: videoPlaybackSession
                ),
                allowsHeroAutomaticAdvance: allowsDashboardHeroAutomaticAdvance,
                onSelectSection: { section in
                    videoPlaybackSession.inlinePlaybackWillNavigate()
                    router.selectDashboardSection(section)
                }
            )

        case .playbackStatistics:
            PlaybackStatisticsView(
                loader: PrismediaPlaybackStatisticsLoader(client: client),
                detailDependencies: detailDependencies,
                navigationPath: pathBinding(
                    for: destination.id,
                    videoPlaybackSession: videoPlaybackSession
                )
            )

        case .administration(let administration):
            AdministrativeDestinationView(
                destination: administration,
                service: AdministrationService(client: client),
                hidesNsfw: !environment.allowsNsfwContent
            )

        case .entityList(let entityList):
            NavigationStack(
                path: pathBinding(
                    for: destination.id,
                    videoPlaybackSession: videoPlaybackSession
                )
            ) {
                destinationLibrary(
                    destination,
                    entityList: entityList,
                    client: client,
                    detailDependencies: detailDependencies
                )
                .prismediaEntityDestinations(dependencies: detailDependencies)
            }

        #if os(iOS) || os(macOS)
            case .manage(let manage):
                ManageDestinationView(
                    destination: manage,
                    service: AdministrationService(client: client),
                    client: client,
                    detailDependencies: detailDependencies,
                    navigationPath: pathBinding(
                        for: destination.id,
                        videoPlaybackSession: videoPlaybackSession
                    )
                )
        #endif
        }
    }

    @ViewBuilder
    private func destinationLibrary(
        _ destination: AppDestination,
        entityList: EntityListDestination,
        client: PrismediaAPIClient,
        detailDependencies: EntityDetailDependencies
    ) -> some View {
        #if os(iOS) || os(macOS)
            if destination.id == "audio-collections" {
                MusicCollectionLibraryView(
                    configuration: EntityGridConfiguration(
                        title: destination.title,
                        query: entityList.query,
                        supportsSearch: entityList.supportsSearch,
                        preferencesID: "audio:collections"
                    ),
                    loader: MusicCollectionCatalogLoader(
                        catalogLoader: PrismediaEntityGridLoader(client: client),
                        collectionItemsLoader: PrismediaEntityDetailLoader(client: client)
                    )
                )
            } else if ["albums", "artists", "tracks"].contains(destination.id) {
                MusicLibraryView(
                    configuration: EntityGridConfiguration(
                        title: destination.title,
                        query: entityList.query,
                        supportsSearch: entityList.supportsSearch
                    ),
                    layout: destination.id == "albums"
                        ? .albums
                        : destination.id == "tracks" ? .tracks : .artists,
                    loader: PrismediaEntityGridLoader(client: client)
                )
            } else {
                genericEntityLibrary(
                    destination,
                    entityList: entityList,
                    client: client,
                    detailDependencies: detailDependencies
                )
            }
        #else
            genericEntityLibrary(
                destination,
                entityList: entityList,
                client: client,
                detailDependencies: detailDependencies
            )
        #endif
    }

    private func genericEntityLibrary(
        _ destination: AppDestination,
        entityList: EntityListDestination,
        client: PrismediaAPIClient,
        detailDependencies: EntityDetailDependencies
    ) -> some View {
        EntityGridView(
            configuration: EntityGridConfiguration(
                title: destination.title,
                query: entityList.query,
                supportsSearch: entityList.supportsSearch
            ),
            loader: PrismediaEntityGridLoader(client: client),
            feedMediaDependencies: EntityMediaFeedDependencies(
                detailLoader: detailDependencies.detailLoader,
                sourceLoader: detailDependencies.imageSourceLoader,
                videoAspectRatioLoader: detailDependencies.imageVideoAspectRatioLoader
            ),
            onOpenFeedItem: { item, mediaSequence in
                router.open(
                    entity: item,
                    within: item.kind == .image ? mediaSequence : nil
                )
            },
            itemContent: { item, layout in
                EntityThumbnailNavigationSurface(item: item, layout: layout)
            }
        )
    }

    #if os(iOS)
        private func iOSShell(
            user: UserAccount,
            client: PrismediaAPIClient
        ) -> some View {
            MusicPlaybackHost(client: client) {
                VideoPlaybackHost(
                    client: client, onRestore: restoreVideoPlayback,
                    content: { session in
                        if horizontalSizeClass == .regular {
                            wideShell(
                                user: user,
                                client: client,
                                videoPlaybackSession: session
                            )
                        } else {
                            tabView(
                                user: user,
                                client: client,
                                videoPlaybackSession: session
                            )
                            .tabBarMinimizeBehavior(.onScrollDown)
                        }
                    })
            }
        }
    #endif

    #if os(macOS)
        private func macOSShell(
            user: UserAccount,
            client: PrismediaAPIClient
        ) -> some View {
            MacMusicPlaybackHost(client: client) {
                VideoPlaybackHost(
                    client: client, onRestore: restoreVideoPlayback,
                    content: { session in
                        wideShell(
                            user: user,
                            client: client,
                            videoPlaybackSession: session
                        )
                    })
            }
        }
    #endif

    private func tabSelection(
        videoPlaybackSession: VideoPlaybackSession
    ) -> Binding<PrismediaTabSelection> {
        Binding(
            get: { router.selectedTab },
            set: { newSelection in
                guard newSelection != router.selectedTab else { return }
                videoPlaybackSession.inlinePlaybackWillNavigate()
                router.select(tab: newSelection, availableModes: availableModes)
            }
        )
    }

    private func pathBinding(
        for destinationID: String,
        videoPlaybackSession: VideoPlaybackSession
    ) -> Binding<[EntityLink]> {
        Binding(
            get: { router.path(for: destinationID) },
            set: { newPath in
                guard newPath != router.path(for: destinationID) else { return }
                videoPlaybackSession.inlinePlaybackWillNavigate()
                router.setPath(newPath, for: destinationID)
            }
        )
    }

    private func restoreVideoPlayback(_ link: EntityLink) {
        Task {
            await router.restoreVideoPlayback(link)
        }
    }

    private func sidebarSelection(
        videoPlaybackSession: VideoPlaybackSession
    ) -> Binding<AppSidebarSelection?> {
        Binding(
            get: {
                switch router.selectedTab {
                case .search:
                    return .search
                case .destination(let destinationID):
                    guard
                        let mode = availableModes.first(where: {
                            $0.destination(id: destinationID) != nil
                        })
                    else { return nil }
                    return .destination(modeID: mode.id, destinationID: destinationID)
                }
            },
            set: { newSelection in
                guard let newSelection else { return }
                videoPlaybackSession.inlinePlaybackWillNavigate()

                switch newSelection {
                case .search:
                    router.select(tab: .search, availableModes: availableModes)
                case .destination(let modeID, let destinationID):
                    guard
                        let mode = availableModes.first(where: { $0.id == modeID }),
                        let destination = mode.destination(id: destinationID)
                    else { return }
                    router.select(mode: mode, destination: destination)
                }
            }
        )
    }

    private var availableModes: [AppMode] {
        ModeCatalog.modes(for: environment.session?.user)
    }

    private var activeTabDestinations: [AppDestination] {
        router.activeTabDestinations(in: availableModes)
    }

    private func selectedDestination(id destinationID: String) -> AppDestination? {
        availableModes.lazy.compactMap { $0.destination(id: destinationID) }.first
    }

    private var allowsDashboardHeroAutomaticAdvance: Bool {
        #if DEBUG
            !PrismediaUITestBootstrap.disablesDashboardHeroAutoAdvance()
        #else
            true
        #endif
    }
}

#if DEBUG && os(iOS)
    #Preview("Native Shell · Overview") {
        PreviewShell(
            signedIn: true,
            initialMode: ModeCatalog.overview,
            initialSelection: "dashboard"
        ) {
            PrismediaShellView()
        }
    }

    #Preview("Native Shell · Audio") {
        PreviewShell(
            signedIn: true,
            initialMode: ModeCatalog.audio,
            initialSelection: "albums"
        ) {
            PrismediaShellView()
        }
    }

    #Preview("Native Shell · Search Selected") {
        PreviewShell(
            signedIn: true,
            initialMode: ModeCatalog.overview,
            initialSelection: "dashboard",
            initialSearchSelected: true
        ) {
            PrismediaShellView()
        }
    }
#endif
