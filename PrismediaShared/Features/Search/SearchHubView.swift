import SwiftUI

/// Prismedia's permanent Browse destination. Its system search field replaces
/// the landing content with navigation and library matches when text is entered.
struct SearchHubView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding private var searchText: String
    @Binding private var filters: SearchHubFilterState
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = SearchHubSnapshot()
    @State private var expandedKinds = Set<EntityKind>()
    @State private var filtersPresented = false

    private let service: SearchHubService
    private let debounce: Duration
    private let detailDependencies: EntityDetailDependencies
    private let modes: [AppMode]
    private let reloadRevision: Int
    private let onSelectMode: (AppMode) -> Void
    private let onSelectDestination: (AppMode, AppDestination) -> Void

    init(
        loader: any SearchHubLoading,
        detailDependencies: EntityDetailDependencies,
        searchText: Binding<String>,
        filters: Binding<SearchHubFilterState> = .constant(SearchHubFilterState()),
        navigationPath: Binding<[EntityLink]> = .constant([]),
        modes: [AppMode],
        reloadRevision: Int = 0,
        debounce: Duration = .milliseconds(300),
        onSelectMode: @escaping (AppMode) -> Void,
        onSelectDestination: @escaping (AppMode, AppDestination) -> Void
    ) {
        _searchText = searchText
        _filters = filters
        _navigationPath = navigationPath
        service = SearchHubService(loader: loader)
        self.debounce = debounce
        self.detailDependencies = detailDependencies
        self.modes = modes
        self.reloadRevision = reloadRevision
        self.onSelectMode = onSelectMode
        self.onSelectDestination = onSelectDestination
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                if usesDedicatedLanding && !isSearchActive {
                    SearchHubDedicatedLandingView(
                        searchText: $searchText,
                        recentItems: snapshot.recentItems,
                        recentState: snapshot.recentState,
                        onRetry: retrySearch
                    )
                    .padding(.top, verticalContentPadding)
                    .padding(.bottom, PrismediaSpacing.section)
                } else {
                    LazyVStack(alignment: .leading, spacing: contentSpacing) {
                        if isSearchActive {
                            SearchHubSearchControls(
                                filters: $filters,
                                usesRegularLayout: usesRegularLayout
                            ) {
                                filtersPresented = true
                            }

                            SearchHubResultsView(
                                expandedKinds: $expandedKinds,
                                snapshot: snapshot,
                                query: normalizedSearchText,
                                navigationMatches: availableNavigationMatches,
                                usesRegularLayout: usesRegularLayout,
                                topResultID: topSearchResult?.id,
                                onSelectNavigation: selectNavigationTarget,
                                onRetrySearch: retrySearch,
                                onRetryPagination: retryPagination,
                                onLoadNextPage: loadNextPage
                            )
                        } else {
                            SearchHubBrowseGrid(
                                modes: modes,
                                recentItems: snapshot.recentItems,
                                onSelectMode: onSelectMode
                            )
                        }
                    }
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, verticalContentPadding)
                    .padding(.bottom, PrismediaSpacing.section)
                    .searchHubContentWidth()
                }
            }
            .prismediaKeyboardDismissal()
            .refreshable {
                await PrismediaRefreshAction.perform {
                    await retryActiveContent()
                }
            }
            .navigationTitle(usesDedicatedLanding ? "Search" : "Browse")
            .accessibilityIdentifier("shell.search")
            .prismediaEntityDestinations(dependencies: detailDependencies)
            .toolbar {
                if isSearchActive {
                    ToolbarItem {
                        Button {
                            filtersPresented = true
                        } label: {
                            Label(
                                filters.isDefault
                                    ? "Filters"
                                    : "Filters, \(filters.activeFilterCount) active",
                                systemImage: filters.isDefault
                                    ? "line.3.horizontal.decrease"
                                    : "line.3.horizontal.decrease.circle.fill"
                            )
                        }
                        .accessibilityHint("Shows rating, date, and entity-kind filters")
                        .accessibilityIdentifier("shell.search.filters")
                    }
                }
            }
        }
        .prismediaScreenBackground()
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Movies, music, books, and more"
            )
        #elseif os(macOS)
            .prismediaMacToolbarSearch(
                text: $searchText,
                prompt: "Movies, music, books, and more",
                onSubmit: openTopResult
            )
        #else
            .searchable(
                text: $searchText,
                prompt: "Movies, music, books, and more"
            )
        #endif
        .onSubmit(of: .search) {
            openTopResult()
        }
        .onKeyPress(.return) {
            guard isSearchActive, topSearchResult != nil else { return .ignored }
            openTopResult()
            return .handled
        }
        .sheet(isPresented: $filtersPresented) {
            NavigationStack {
                SearchHubFilterControls(filters: $filters)
            }
            .presentationDetents([.medium, .large])
        }
        .task(id: reloadRevision) {
            await loadRecent()
        }
        .task(id: searchTaskID) {
            expandedKinds.removeAll()
            await updateSearch(for: normalizedSearchText, debounce: debounce)
        }
    }

    private var isSearchActive: Bool {
        !normalizedSearchText.isEmpty
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchTaskID: SearchHubTaskID {
        SearchHubTaskID(
            query: normalizedSearchText,
            filters: filters,
            revision: reloadRevision
        )
    }

    private var usesRegularLayout: Bool {
        horizontalSizeClass != .compact
    }

    private var usesDedicatedLanding: Bool {
        #if os(macOS)
            true
        #elseif os(iOS)
            horizontalSizeClass == .regular
        #else
            false
        #endif
    }

    private var contentSpacing: CGFloat {
        usesRegularLayout ? PrismediaSpacing.extraExtraLarge : PrismediaSpacing.section
    }

    private var horizontalContentPadding: CGFloat {
        usesRegularLayout ? PrismediaSpacing.extraExtraLarge : PrismediaSpacing.extraLarge
    }

    private var verticalContentPadding: CGFloat {
        usesRegularLayout ? PrismediaSpacing.extraLarge : PrismediaSpacing.small
    }

    private var availableNavigationMatches: [SearchHubNavigationTarget] {
        let allowedModeIDs = Set(modes.map(\.id))
        return SearchHubCatalog.navigationMatches(for: normalizedSearchText)
            .filter { allowedModeIDs.contains($0.mode.id) }
    }

    private var topSearchResult: EntityThumbnail? {
        SearchHubCatalog.groupedResults(
            snapshot.searchResults,
            query: normalizedSearchText
        )
        .first?
        .items
        .first
    }

    private func openTopResult() {
        guard let topSearchResult else { return }
        navigationPath.append(EntityLink(thumbnail: topSearchResult))
    }

    private func selectNavigationTarget(_ target: SearchHubNavigationTarget) {
        onSelectDestination(target.mode, target.destination)
    }

    private func retrySearch() {
        Task { await retryActiveContent() }
    }

    private func retryPagination() {
        Task { await loadNextSearchPage() }
    }

    private func loadNextPage() {
        Task { await loadNextSearchPage() }
    }

    private func retryActiveContent() async {
        if isSearchActive {
            await updateSearch(for: normalizedSearchText, debounce: .zero)
        } else {
            await loadRecent()
        }
    }

    private func loadRecent() async {
        let request = snapshot.beginRecentLoad()

        do {
            let page = try await service.loadRecent()
            guard !Task.isCancelled else {
                snapshot.cancelRecent(for: request)
                return
            }
            snapshot.receiveRecent(page, for: request)
        } catch is CancellationError {
            snapshot.cancelRecent(for: request)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancelRecent(for: request)
                return
            }
            snapshot.failRecent(for: request)
        }
    }

    private func updateSearch(for query: String, debounce: Duration) async {
        guard let request = snapshot.beginSearch(query: query, filters: filters) else { return }

        do {
            let page = try await service.search(request: request, debounce: debounce)
            guard !Task.isCancelled else {
                snapshot.cancelSearch(for: request, currentQuery: normalizedSearchText)
                return
            }
            snapshot.receiveSearch(
                page,
                for: request,
                currentQuery: normalizedSearchText
            )
        } catch is CancellationError {
            snapshot.cancelSearch(for: request, currentQuery: normalizedSearchText)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancelSearch(for: request, currentQuery: normalizedSearchText)
                return
            }
            snapshot.failSearch(
                for: request,
                currentQuery: normalizedSearchText
            )
        }
    }

    private func loadNextSearchPage() async {
        guard let request = snapshot.beginNextSearchPage(currentQuery: normalizedSearchText) else { return }

        do {
            let page = try await service.search(request: request, debounce: .zero)
            guard !Task.isCancelled else {
                snapshot.cancelNextSearchPage(for: request, currentQuery: normalizedSearchText)
                return
            }
            snapshot.receiveNextSearchPage(
                page,
                for: request,
                currentQuery: normalizedSearchText
            )
        } catch is CancellationError {
            snapshot.cancelNextSearchPage(for: request, currentQuery: normalizedSearchText)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancelNextSearchPage(for: request, currentQuery: normalizedSearchText)
                return
            }
            snapshot.failNextSearchPage(for: request, currentQuery: normalizedSearchText)
        }
    }

}

#if DEBUG

    #Preview("Browse · Direct") {
        @Previewable @State var searchText = ""
        let detailLoader = SearchHubPreviewDetailLoader()

        SearchHubView(
            loader: SearchHubPreviewLoader(),
            detailDependencies: EntityDetailDependencies(
                detailLoader: detailLoader,
                mutator: nil,
                collectionItemsLoader: nil,
                readerService: nil,
                videoPlaybackService: nil,
                onEntityMutated: {}
            ),
            searchText: $searchText,
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            debounce: .milliseconds(10),
            onSelectMode: { _ in },
            onSelectDestination: { _, _ in }
        )
    }

    #if os(iOS)
        #Preview("Browse · Admin") {
            PreviewShell(signedIn: true) {
                SearchHubPreview()
            }
        }

        #Preview("Browse · Member") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    user: UserAccount(
                        id: UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!,
                        username: "member",
                        displayName: "Library Member",
                        role: .member
                    )
                )
            }
        }

        #Preview("Browse · Suggested Loading") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(loader: SearchHubPreviewLoader(recent: .loading))
            }
        }

        #Preview("Browse · Fallback Artwork") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    loader: SearchHubPreviewLoader(
                        recent: .items(
                            PrismediaPreviewData.allEntities.map {
                                EntityThumbnail(id: $0.id, kind: $0.kind, title: $0.title)
                            })
                    )
                )
            }
        }

        #Preview("Browse · Empty Library") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(loader: SearchHubPreviewLoader(recent: .items([])))
            }
        }

        #Preview("Browse · Search Results") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    searchText: "Chair",
                    loader: SearchHubPreviewLoader(search: .items([PrismediaPreviewData.series]))
                )
            }
        }

        #Preview("Browse · Active Search Filters") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    searchText: "a",
                    filters: SearchHubFilterState(
                        selectedKinds: [.movie, .videoSeries, .video],
                        minimumRating: 4
                    ),
                    loader: SearchHubPreviewLoader(search: .items(PrismediaPreviewData.allEntities))
                )
            }
        }

        #Preview("Browse · Searching") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    searchText: "Matrix",
                    loader: SearchHubPreviewLoader(search: .loading)
                )
            }
        }

        #Preview("Browse · No Results") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    searchText: "Nothing Here",
                    loader: SearchHubPreviewLoader(search: .items([]))
                )
            }
        }

        #Preview("Browse · Offline Error") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(
                    searchText: "Arrival",
                    loader: SearchHubPreviewLoader(search: .failure)
                )
            }
        }

        #Preview("Browse · Accessibility XXXL") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(dynamicTypeSize: .accessibility5)
            }
        }

        #Preview("Browse · iPad") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(searchText: "a")
            }
            .frame(width: 1024, height: 1366)
        }
    #elseif os(macOS)
        #Preview("Browse · macOS") {
            PreviewShell(signedIn: true) {
                SearchHubPreview(searchText: "a")
            }
            .frame(width: 980, height: 760)
        }
    #elseif os(tvOS)
        #Preview("Browse · tvOS") {
            PreviewShell(signedIn: true) {
                SearchHubPreview()
            }
        }
    #endif
#endif
