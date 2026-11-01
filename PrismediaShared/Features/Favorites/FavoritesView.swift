import SwiftUI

struct FavoritesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var navigationPath: NavigationPath
    @State private var snapshot = FavoritesSnapshot()
    @State private var loadedRevision: Int?
    /// The kind whose grid shows beside the list on a wide display.
    @State private var selectedSectionID: FavoritesSection.ID?

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
                    if usesSectionPanes {
                        PrismediaWidePanes {
                            FavoritesSectionList(
                                sections: favoritedSections,
                                selectedID: focusedSection?.id,
                                onSelect: { selectedSectionID = $0.id }
                            )
                        } secondary: {
                            if let focusedSection {
                                sectionGrid(focusedSection.definition)
                                    .id(focusedSection.id)
                            }
                        } combined: {
                            sectionRails
                        }
                    } else {
                        sectionRails
                    }

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
                sectionGrid(section)
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

    private var sectionRails: some View {
        FavoritesSectionsView(
            sections: snapshot.sections,
            onSelect: openSection
        )
    }

    private func sectionGrid(_ section: FavoritesSectionDefinition) -> some View {
        FavoriteEntityGridView(
            section: section,
            loader: gridLoader,
            detailDependencies: detailDependencies,
            actionPolicy: actionPolicy,
            mutationService: mutationService
        )
    }

    /// Regular width lists the kinds beside the selected kind's grid wherever
    /// the page is wider than tall; elsewhere each kind is a rail.
    private var usesSectionPanes: Bool {
        #if os(iOS)
            horizontalSizeClass == .regular
        #else
            false
        #endif
    }

    /// The kinds with at least one favorite; the rails hide empty kinds too.
    private var favoritedSections: [FavoritesSection] {
        snapshot.sections.filter { !$0.items.isEmpty }
    }

    private var focusedSection: FavoritesSection? {
        favoritedSections.first { $0.id == selectedSectionID } ?? favoritedSections.first
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
