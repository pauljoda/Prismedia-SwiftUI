#if os(macOS)
import SwiftUI

struct MacSearchHubView: View {
    @Binding private var searchText: String
    @Binding private var filters: SearchHubFilterState
    @Binding private var navigationPath: [EntityLink]
    @FocusState private var searchFieldFocused: Bool
    @State private var snapshot = SearchHubSnapshot()
    @State private var expandedKinds = Set<EntityKind>()
    @State private var filtersPresented = false

    private let service: SearchHubService
    private let detailDependencies: EntityDetailDependencies
    private let modes: [AppMode]
    private let reloadRevision: Int
    private let debounce: Duration
    private let onSelectDestination: (AppMode, AppDestination) -> Void

    init(
        loader: any SearchHubLoading,
        detailDependencies: EntityDetailDependencies,
        searchText: Binding<String>,
        filters: Binding<SearchHubFilterState>,
        navigationPath: Binding<[EntityLink]>,
        modes: [AppMode],
        reloadRevision: Int,
        debounce: Duration = .milliseconds(300),
        onSelectDestination: @escaping (AppMode, AppDestination) -> Void
    ) {
        service = SearchHubService(loader: loader)
        self.detailDependencies = detailDependencies
        _searchText = searchText
        _filters = filters
        _navigationPath = navigationPath
        self.modes = modes
        self.reloadRevision = reloadRevision
        self.debounce = debounce
        self.onSelectDestination = onSelectDestination
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                    if isSearchActive {
                        SearchHubSearchControls(filters: $filters, usesRegularLayout: true) {
                            filtersPresented = true
                        }

                        SearchHubResultsView(
                            expandedKinds: $expandedKinds,
                            snapshot: snapshot,
                            query: normalizedSearchText,
                            navigationMatches: availableNavigationMatches,
                            usesRegularLayout: true,
                            topResultID: topSearchResult?.id,
                            onSelectNavigation: selectNavigationTarget,
                            onRetrySearch: retrySearch,
                            onRetryPagination: retryPagination,
                            onLoadNextPage: loadNextPage
                        )
                    } else {
                        searchLanding
                    }
                }
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
                .padding(.vertical, PrismediaSpacing.extraLarge)
                .containerRelativeFrame(.horizontal, alignment: .center) { length, _ in
                    min(length, SearchHubLayout.maximumContentWidth)
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Search")
            .accessibilityIdentifier("shell.search")
            .prismediaEntityDestinations(dependencies: detailDependencies)
            .toolbar {
                if isSearchActive {
                    ToolbarItem(placement: .primaryAction) {
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
                        .accessibilityIdentifier("shell.search.filters")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Movies, music, books, and more")
        .onSubmit(of: .search, openTopResult)
        .onKeyPress(.return) {
            guard isSearchActive, topSearchResult != nil else { return .ignored }
            openTopResult()
            return .handled
        }
        .sheet(isPresented: $filtersPresented) {
            NavigationStack {
                SearchHubFilterControls(filters: $filters)
            }
            .frame(minWidth: 520, minHeight: 480)
        }
        .task(id: reloadRevision) { await loadRecent() }
        .task(id: searchTaskID) {
            expandedKinds.removeAll()
            await updateSearch(for: normalizedSearchText, debounce: debounce)
        }
    }

    private var searchLanding: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            VStack(spacing: PrismediaSpacing.medium) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(PrismediaColor.accent)
                Text("Search your library")
                    .font(.largeTitle.bold())
                Text("Find movies, series, music, books, people, and collections.")
                    .font(.title3)
                    .foregroundStyle(PrismediaColor.textSecondary)

                TextField("Movies, music, books, and more", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .focused($searchFieldFocused)
                    .frame(maxWidth: 620)
                    .accessibilityIdentifier("shell.search.primary-field")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PrismediaSpacing.extraExtraLarge)

            if !snapshot.recentItems.isEmpty {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    Label("Recently Added", systemImage: "clock.arrow.circlepath")
                        .font(.title2.bold())

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: PrismediaSpacing.large),
                            GridItem(.flexible(), spacing: PrismediaSpacing.large),
                        ],
                        spacing: PrismediaSpacing.small
                    ) {
                        ForEach(snapshot.recentItems.prefix(12)) { item in
                            recentItem(item)
                        }
                    }
                }
            } else if snapshot.recentState == .loading || snapshot.recentState == .idle {
                ProgressView("Loading recent additions…")
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear { searchFieldFocused = true }
    }

    private func recentItem(_ item: EntityThumbnail) -> some View {
        NavigationLink(value: EntityLink(thumbnail: item)) {
            HStack(spacing: PrismediaSpacing.medium) {
                EntityThumbnailCompactArtworkView(item: item, width: 52)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                    Text(item.kind.displayLabel)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var isSearchActive: Bool { !normalizedSearchText.isEmpty }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchTaskID: SearchHubTaskID {
        SearchHubTaskID(query: normalizedSearchText, filters: filters, revision: reloadRevision)
    }

    private var availableNavigationMatches: [SearchHubNavigationTarget] {
        let allowedModeIDs = Set(modes.map(\.id))
        return SearchHubCatalog.navigationMatches(for: normalizedSearchText)
            .filter { allowedModeIDs.contains($0.mode.id) }
    }

    private var topSearchResult: EntityThumbnail? {
        SearchHubCatalog.groupedResults(snapshot.searchResults, query: normalizedSearchText)
            .first?.items.first
    }

    private func openTopResult() {
        guard let topSearchResult else { return }
        navigationPath.append(EntityLink(thumbnail: topSearchResult))
    }

    private func selectNavigationTarget(_ target: SearchHubNavigationTarget) {
        onSelectDestination(target.mode, target.destination)
    }

    private func retrySearch() { Task { await retryActiveContent() } }
    private func retryPagination() { Task { await loadNextSearchPage() } }
    private func loadNextPage() { Task { await loadNextSearchPage() } }

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
            snapshot.receiveSearch(page, for: request, currentQuery: normalizedSearchText)
        } catch is CancellationError {
            snapshot.cancelSearch(for: request, currentQuery: normalizedSearchText)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancelSearch(for: request, currentQuery: normalizedSearchText)
                return
            }
            snapshot.failSearch(for: request, currentQuery: normalizedSearchText)
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
            snapshot.receiveNextSearchPage(page, for: request, currentQuery: normalizedSearchText)
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
    #Preview("Mac Search Hub", traits: .fixedLayout(width: 1_080, height: 760)) {
        @Previewable @State var searchText = ""
        @Previewable @State var filters = SearchHubFilterState()
        @Previewable @State var navigationPath: [EntityLink] = []
        let detailLoader = SearchHubPreviewDetailLoader()

        MacSearchHubView(
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
            filters: $filters,
            navigationPath: $navigationPath,
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            reloadRevision: 0,
            debounce: .milliseconds(10),
            onSelectDestination: { _, _ in }
        )
    }
#endif
#endif
