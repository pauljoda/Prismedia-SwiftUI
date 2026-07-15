import SwiftUI

struct DashboardView: View {
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = DashboardSnapshot()
    private let service: DashboardService
    private let detailDependencies: EntityDetailDependencies
    private let user: UserAccount
    private let allowsNsfwContent: Bool
    private let launchBrandNamespace: Namespace.ID?
    private let showsHero: Bool
    private let allowsHeroAutomaticAdvance: Bool
    private let reloadRevision: Int
    private let onSelectSection: (DashboardSectionDefinition) -> Void
    private let onOpenSettings: (() -> Void)?
    private let onSetAllowsNsfwContent: @MainActor @Sendable (Bool) -> Void
    private let onSignOut: () -> Void

    init(
        loader: any DashboardLoading,
        detailDependencies: EntityDetailDependencies,
        user: UserAccount,
        navigationPath: Binding<[EntityLink]> = .constant([]),
        allowsNsfwContent: Bool,
        launchBrandNamespace: Namespace.ID? = nil,
        showsHero: Bool = false,
        allowsHeroAutomaticAdvance: Bool = true,
        reloadRevision: Int = 0,
        onSelectSection: @escaping (DashboardSectionDefinition) -> Void,
        onOpenSettings: (() -> Void)?,
        onSetAllowsNsfwContent: @escaping @MainActor @Sendable (Bool) -> Void,
        onSignOut: @escaping () -> Void
    ) {
        _navigationPath = navigationPath
        service = DashboardService(loader: loader)
        self.detailDependencies = detailDependencies
        self.user = user
        self.allowsNsfwContent = allowsNsfwContent
        self.launchBrandNamespace = launchBrandNamespace
        self.showsHero = showsHero
        self.allowsHeroAutomaticAdvance = allowsHeroAutomaticAdvance
        self.reloadRevision = reloadRevision
        self.onSelectSection = onSelectSection
        self.onOpenSettings = onOpenSettings
        self.onSetAllowsNsfwContent = onSetAllowsNsfwContent
        self.onSignOut = onSignOut
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
                                if showsHero, !snapshot.featuredItems.isEmpty {
                                    DashboardHeroCarouselView(
                                        items: snapshot.featuredItems,
                                        viewportWidth: viewport.size.width,
                                        viewportHeight: viewport.size.height
                                            + viewport.safeAreaInsets.top,
                                        allowsAutomaticAdvance: allowsHeroAutomaticAdvance,
                                        onNavigate: navigate
                                    )
                                }
                                DashboardShelfView(
                                    title: "Continue Watching",
                                    systemImage: "play.circle.fill",
                                    colorRole: .continueWatching,
                                    items: visibleContinueItems,
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
                            edges: showsHero && !snapshot.featuredItems.isEmpty ? .top : []
                        )
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Prismedia")
            .prismediaInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    dashboardBrandTitle
                }

                ToolbarItem(placement: .primaryAction) {
                    PrismediaAccountMenu(
                        user: user,
                        allowsNsfwContent: allowsNsfwContent,
                        onOpenSettings: onOpenSettings,
                        onSetAllowsNsfwContent: onSetAllowsNsfwContent,
                        onSignOut: onSignOut
                    )
                }
            }
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

    private var visibleContinueItems: [EntityThumbnail] {
        guard showsHero, let heroID = snapshot.hero?.id else {
            return snapshot.continueItems
        }

        var removedHero = false
        return snapshot.continueItems.filter { item in
            guard !removedHero, item.id == heroID else { return true }
            removedHero = true
            return false
        }
    }

    private var dashboardBrandTitle: some View {
        HStack(spacing: PrismediaSpacing.small) {
            dashboardBrandMark

            Text("Prismedia")
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prismedia")
    }

    @ViewBuilder
    private var dashboardBrandMark: some View {
        if let launchBrandNamespace {
            PrismediaBrandView(markSize: 26, isDecorative: true)
                .matchedGeometryEffect(
                    id: "prismedia.launch.brand",
                    in: launchBrandNamespace,
                    isSource: false
                )
        } else {
            PrismediaBrandView(markSize: 26, isDecorative: true)
        }
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
                user: PrismediaPreviewData.user,
                allowsNsfwContent: false,
                onSelectSection: { _ in },
                onOpenSettings: {},
                onSetAllowsNsfwContent: { _ in },
                onSignOut: {}
            )
        }
    }
#endif
