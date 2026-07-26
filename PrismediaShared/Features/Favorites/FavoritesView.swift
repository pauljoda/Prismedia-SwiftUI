import SwiftUI

struct FavoritesView: View {
    @Binding private var navigationPath: NavigationPath
    @State private var snapshot = FavoritesSnapshot()
    @State private var loadedRevision: Int?

    private let service: FavoritesService
    private let gridLoader: any EntityGridLoading
    private let detailDependencies: EntityDetailDependencies
    private let reloadRevision: Int
    private let actionPolicy: EntityGridActionPolicy
    private let mutationService: (any EntityGridMutationServicing)?

    init(
        loader: any FavoritesLoading,
        gridLoader: any EntityGridLoading,
        detailDependencies: EntityDetailDependencies,
        navigationPath: Binding<NavigationPath> = .constant(NavigationPath()),
        reloadRevision: Int = 0,
        actionPolicy: EntityGridActionPolicy = .disabled,
        mutationService: (any EntityGridMutationServicing)? = nil
    ) {
        service = FavoritesService(loader: loader)
        self.gridLoader = gridLoader
        self.detailDependencies = detailDependencies
        _navigationPath = navigationPath
        self.reloadRevision = reloadRevision
        self.actionPolicy = actionPolicy
        self.mutationService = mutationService
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch snapshot.state {
                case .idle, .loading:
                    PrismediaLoadingView("Loading favorites…")

                case .content:
                    FavoritesSectionsView(
                        sections: snapshot.sections,
                        onSelect: openSection
                    )

                case .empty:
                    ScrollView {
                        ContentUnavailableView(
                            "No Favorites Yet",
                            systemImage: "heart",
                            description: Text(
                                "Entities you mark as favorites will appear here."
                            )
                        )
                        .frame(maxWidth: .infinity, minHeight: 320)
                    }
                    .scrollBounceBehavior(.always, axes: .vertical)
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Favorites")
            .prismediaInlineNavigationTitle()
            .refreshable {
                await PrismediaRefreshAction.perform {
                    _ = await reload(preservingContent: true)
                }
            }
            .navigationDestination(for: FavoritesSectionDefinition.self) { section in
                FavoriteEntityGridView(
                    section: section,
                    loader: gridLoader,
                    detailDependencies: detailDependencies,
                    actionPolicy: actionPolicy,
                    mutationService: mutationService
                )
            }
            .prismediaEntityDestinations(dependencies: detailDependencies)
        }
        .task(id: reloadRevision) {
            guard loadedRevision != reloadRevision else { return }
            if await reload(preservingContent: true) {
                loadedRevision = reloadRevision
            }
        }
        .accessibilityIdentifier("shell.favorites")
    }

    private func openSection(_ definition: FavoritesSectionDefinition) {
        navigationPath.append(definition)
    }

    @discardableResult
    private func reload(
        preservingContent: Bool
    ) async -> Bool {
        if !preservingContent || snapshot.state == .idle {
            snapshot.state = .loading
        }
        let loaded = await service.load()
        guard !Task.isCancelled else { return false }
        snapshot = loaded
        return true
    }
}

#if DEBUG
    #Preview("Favorites · Content") {
        let detailLoader = DashboardPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            FavoritesView(
                loader: FavoritesPreviewLoader(items: PrismediaPreviewData.videos),
                gridLoader: StaticEntityGridLoader(items: PrismediaPreviewData.videos),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: detailLoader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {}
                )
            )
        }
    }

    #Preview("Favorites · Empty") {
        let detailLoader = DashboardPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            FavoritesView(
                loader: FavoritesPreviewLoader(items: []),
                gridLoader: StaticEntityGridLoader(items: []),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: detailLoader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {}
                )
            )
        }
    }
#endif
