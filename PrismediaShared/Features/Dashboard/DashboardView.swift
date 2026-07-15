import SwiftUI

struct DashboardView: View {
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = DashboardSnapshot()
    private let service: DashboardService
    private let detailDependencies: EntityDetailDependencies
    private let allowsHeroAutomaticAdvance: Bool
    private let reloadRevision: Int
    private let onSelectSection: (DashboardSectionDefinition) -> Void

    init(
        loader: any DashboardLoading,
        detailDependencies: EntityDetailDependencies,
        navigationPath: Binding<[EntityLink]> = .constant([]),
        allowsHeroAutomaticAdvance: Bool = true,
        reloadRevision: Int = 0,
        onSelectSection: @escaping (DashboardSectionDefinition) -> Void
    ) {
        _navigationPath = navigationPath
        service = DashboardService(loader: loader)
        self.detailDependencies = detailDependencies
        self.allowsHeroAutomaticAdvance = allowsHeroAutomaticAdvance
        self.reloadRevision = reloadRevision
        self.onSelectSection = onSelectSection
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch snapshot.state {
                case .idle, .loading:
                    PrismediaLoadingView("Loading dashboard…")

                case .content, .empty:
                    GeometryReader { viewport in
                        ScrollView {
                            LazyVStack(
                                alignment: .leading,
                                spacing: PrismediaSpacing.extraExtraLarge
                            ) {
                                if !snapshot.featuredItems.isEmpty {
                                    DashboardHeroCarouselView(
                                        items: snapshot.featuredItems,
                                        viewportWidth: viewport.size.width,
                                        topSafeAreaHeight: viewport.safeAreaInsets.top,
                                        allowsAutomaticAdvance: allowsHeroAutomaticAdvance,
                                        onNavigate: navigate
                                    )
                                }
                                DashboardShelfView(
                                    title: "Continue Watching",
                                    systemImage: "play.circle.fill",
                                    colorRole: .continueWatching,
                                    items: snapshot.continueItems,
                                    onSelect: nil
                                )
                                DashboardShelfView(
                                    title: "Recent",
                                    systemImage: "clock.arrow.circlepath",
                                    colorRole: .recent,
                                    items: snapshot.recentItems,
                                    onSelect: nil
                                )
                                ForEach(snapshot.sections) { section in
                                    DashboardShelfView(
                                        title: section.title,
                                        systemImage: section.systemImage,
                                        colorRole: section.definition.colorRole,
                                        items: section.items,
                                        onSelect: { onSelectSection(section.definition) }
                                    )
                                }
                                if snapshot.state == .empty {
                                    ContentUnavailableView(
                                        "Your Library Is Ready",
                                        systemImage: "sparkles.rectangle.stack",
                                        description: Text("New media and playback activity will appear here.")
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 300)
                                }
                            }
                            .padding(.bottom, PrismediaSpacing.section)
                            .frame(width: viewport.size.width, alignment: .leading)
                        }
                        .ignoresSafeArea(
                            .container,
                            edges: snapshot.featuredItems.isEmpty ? [] : .top
                        )
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("")
            .prismediaInlineNavigationTitle()
            #if os(iOS)
                .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .refreshable { await reload() }
            .prismediaEntityDestinations(dependencies: detailDependencies)
        }
        .task(id: reloadRevision) {
            await reload()
        }
        .accessibilityIdentifier("shell.dashboard")
    }

    private func reload() async {
        snapshot.state = .loading
        let loaded = await service.load()
        guard !Task.isCancelled else { return }
        snapshot = loaded
    }

    private func navigate(_ link: EntityLink) {
        navigationPath.append(link)
    }
}

#if DEBUG

    #Preview("Dashboard") {
        let detailLoader = DashboardPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            DashboardView(
                loader: DashboardPreviewLoader(),
                detailDependencies: EntityDetailDependencies(
                    detailLoader: detailLoader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {}
                ),
                onSelectSection: { _ in }
            )
        }
    }
#endif
