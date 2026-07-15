import SwiftUI

#if os(tvOS)
    struct PrismediaTVShellView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        let user: UserAccount
        let client: PrismediaAPIClient
        @State private var selectedTabID = "home"
        @State private var hasAdoptedInitialRouterTab = false
        @State private var tabFocusCoordinator = TVTabFocusCoordinator()
        @FocusState private var focusedTabID: String?

        var body: some View {
            VideoPlaybackHost(
                client: client, onRestore: { _ in },
                content: { _ in
                    TabView(selection: $selectedTabID) {
                        ForEach(TVAppCatalog.tabs) { tab in
                            Tab(value: tab.id) {
                                NavigationStack(path: pathBinding(for: tab)) {
                                    tabContent(tab)
                                        .ignoresSafeArea(.container, edges: .horizontal)
                                        .prismediaEntityDestinations(
                                            dependencies: detailDependencies
                                        )
                                }
                            } label: {
                                Label(tab.title, systemImage: tab.systemImage)
                                    .foregroundStyle(
                                        selectedTabID == tab.id ? PrismediaColor.onAccent : PrismediaColor.onMedia
                                    )
                                    .focused($focusedTabID, equals: tab.id)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(tabFocusCoordinator)
                    .onExitCommand(perform: tabBarBackAction)
                    .onChange(of: tabFocusCoordinator.requestGeneration) { _, _ in
                        focusedTabID = selectedTabID
                    }
                    .onChange(of: selectedTabID, initial: true) { _, tabID in
                        if !hasAdoptedInitialRouterTab {
                            hasAdoptedInitialRouterTab = true
                            let initialTabID = initialTabIDFromRouter
                            if initialTabID != tabID {
                                selectedTabID = initialTabID
                                return
                            }
                        }
                        selectRouterTab(tabID)
                    }
                }
            )
            .accessibilityIdentifier("tv.shell")
        }

        @ViewBuilder
        private func tabContent(_ tab: TVAppTab) -> some View {
            if tab.id == "home" {
                TVHomeView(client: client) { selectedTabID = $0 }
            } else if tab.id == "account" {
                TVAccountView(user: user) {
                    Task { await environment.signOut() }
                }
            } else if let query = tab.query {
                let isSearch = tab.id == "search"
                let presentsVideoList = query.kind == .video
                let dependencies = detailDependencies
                EntityGridView(
                    configuration: EntityGridConfiguration(
                        title: tab.title,
                        query: query,
                        supportsSearch: isSearch,
                        minimumColumnWidth: 270,
                        defaultDisplayMode: presentsVideoList ? .list : .grid,
                        availableDisplayModes: presentsVideoList
                            ? [.list]
                            : EntityGridDisplayMode.allCases
                    ),
                    loader: PrismediaEntityGridLoader(client: client),
                    feedMediaDependencies: EntityMediaFeedDependencies(
                        detailLoader: dependencies.detailLoader,
                        sourceLoader: dependencies.imageSourceLoader,
                        videoAspectRatioLoader: dependencies.imageVideoAspectRatioLoader
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
        }

        private var detailDependencies: EntityDetailDependencies {
            PrismediaEntityDetailComposition.dependencies(
                client: client,
                userID: user.id,
                isAdministrator: user.isAdmin,
                onEntityMutated: { environment.entityDidMutate() }
            )
        }

        private func pathBinding(for tab: TVAppTab) -> Binding<[EntityLink]> {
            let pathID = pathID(for: tab)
            return Binding(
                get: { router.path(for: pathID) },
                set: { router.setPath($0, for: pathID) }
            )
        }

        private var tabBarBackAction: (() -> Void)? {
            let pathID = selectedTabID == "home" ? "dashboard" : selectedTabID
            guard !router.path(for: pathID).isEmpty else { return nil }
            return { router.navigateBack(in: pathID) }
        }

        private func pathID(for tab: TVAppTab) -> String {
            tab.id == "home" ? "dashboard" : tab.id
        }

        private func selectRouterTab(_ tabID: String) {
            if tabID == "account" { return }

            if tabID == "search" {
                router.select(
                    tab: .search,
                    availableModes: ModeCatalog.modes(for: user)
                )
                return
            }

            let destinationID = tabID == "home" ? "dashboard" : tabID
            guard
                let mode = ModeCatalog.mode(containing: destinationID),
                let destination = mode.destination(id: destinationID)
            else { return }
            router.select(mode: mode, destination: destination)
        }

        private var initialTabIDFromRouter: String {
            #if DEBUG
                if let tabID = PrismediaUITestBootstrap.tvTabID() { return tabID }
            #endif
            let destinationID = router.navigation.destinationID
            if destinationID == "dashboard" { return "home" }
            return TVAppCatalog.tabs.contains(where: { $0.id == destinationID })
                ? destinationID
                : "home"
        }
    }

    #if DEBUG
        #Preview("Prismedia TV Shell") {
            let model = PrismediaPreviewData.model(signedIn: true)
            PrismediaTVShellView(user: model.session!.user, client: model.client!)
                .environment(model)
        }
    #endif
#endif
