import SwiftUI

/// Prismedia's permanent Browse destination. Its system search field replaces
/// the landing content with navigation and library matches when text is entered.
struct SearchHubView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding private var searchText: String
    @Binding private var navigationPath: [EntityLink]
    @State private var snapshot = SearchHubSnapshot()

    private let service: SearchHubService
    private let debounce: Duration
    private let detailDependencies: EntityDetailDependencies
    private let user: UserAccount
    private let modes: [AppMode]
    private let allowsNsfwContent: Bool
    private let reloadRevision: Int
    private let onSetAllowsNsfwContent: @MainActor @Sendable (Bool) -> Void
    private let onSelectMode: (AppMode) -> Void
    private let onSelectDestination: (AppMode, AppDestination) -> Void
    private let onSignOut: () -> Void

    init(
        loader: any SearchHubLoading,
        detailDependencies: EntityDetailDependencies,
        searchText: Binding<String>,
        navigationPath: Binding<[EntityLink]> = .constant([]),
        user: UserAccount,
        modes: [AppMode],
        allowsNsfwContent: Bool,
        reloadRevision: Int = 0,
        debounce: Duration = .milliseconds(300),
        onSelectMode: @escaping (AppMode) -> Void,
        onSelectDestination: @escaping (AppMode, AppDestination) -> Void,
        onSetAllowsNsfwContent: @escaping @MainActor @Sendable (Bool) -> Void,
        onSignOut: @escaping () -> Void
    ) {
        _searchText = searchText
        _navigationPath = navigationPath
        service = SearchHubService(loader: loader)
        self.debounce = debounce
        self.detailDependencies = detailDependencies
        self.user = user
        self.modes = modes
        self.allowsNsfwContent = allowsNsfwContent
        self.reloadRevision = reloadRevision
        self.onSelectMode = onSelectMode
        self.onSelectDestination = onSelectDestination
        self.onSetAllowsNsfwContent = onSetAllowsNsfwContent
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isInitialSearchLoading {
                    PrismediaLoadingView("Searching Prismedia…")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PrismediaSpacing.section) {
                            if isSearchActive {
                                searchResults
                            } else {
                                browseLanding
                            }
                        }
                        .padding(.horizontal, PrismediaSpacing.extraLarge)
                        .padding(.top, PrismediaSpacing.small)
                        .padding(.bottom, PrismediaSpacing.section)
                        .containerRelativeFrame(.horizontal, alignment: .center) { length, _ in
                            min(length, 960)
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .prismediaKeyboardDismissal()
            .refreshable {
                await retryActiveContent()
            }
            .navigationTitle("Browse")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    accountMenu
                }
            }
            .accessibilityIdentifier("shell.search")
            .prismediaEntityDestinations(dependencies: detailDependencies)
        }
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Movies, music, books, and more"
            )
        #else
            .searchable(
                text: $searchText,
                prompt: "Movies, music, books, and more"
            )
        #endif
        .task(id: reloadRevision) {
            await loadRecent()
        }
        .task(id: SearchHubTaskID(query: normalizedSearchText, revision: reloadRevision)) {
            await updateSearch(for: normalizedSearchText, debounce: debounce)
        }
    }

    private var isSearchActive: Bool {
        !normalizedSearchText.isEmpty
    }

    private var isInitialSearchLoading: Bool {
        guard isSearchActive, snapshot.searchResults.isEmpty else { return false }
        return snapshot.searchState == .idle || snapshot.searchState == .loading
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Browse landing

    private var browseLanding: some View {
        LazyVGrid(columns: browseColumns, spacing: PrismediaSpacing.medium) {
            ForEach(SearchHubCatalog.cards(for: modes)) { card in
                modeCard(card)
            }
        }
    }

    private var browseColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: PrismediaSpacing.medium)]
        }

        if horizontalSizeClass == .compact {
            return [
                GridItem(.flexible(), spacing: PrismediaSpacing.medium),
                GridItem(.flexible(), spacing: PrismediaSpacing.medium),
            ]
        }

        return [GridItem(.adaptive(minimum: 164, maximum: 280), spacing: PrismediaSpacing.medium)]
    }

    private func modeCard(_ card: SearchHubModeCard) -> some View {
        let artwork = representativeArtwork(for: card)

        return Button {
            onSelectMode(card.mode)
        } label: {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 180 : 124)
                .background {
                    RemotePosterImage(
                        path: artwork?.bestCoverPath,
                        fallbackSeed: artwork?.title ?? card.title,
                        systemImage: card.systemImage
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            .clear,
                            PrismediaColor.background.opacity(PrismediaOpacity.statusFill),
                            PrismediaColor.background.opacity(0.88),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(card.title)
                            .font(.title3.bold())
                            .foregroundStyle(PrismediaColor.onMedia)

                        Text(card.subtitle)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(PrismediaSpacing.large)
                }
                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.title). \(card.subtitle)")
        .accessibilityHint("Opens the \(card.title) section")
        .accessibilityIdentifier("shell.search.mode.\(card.id)")
    }

    private func representativeArtwork(for card: SearchHubModeCard) -> EntityThumbnail? {
        snapshot.recentItems.first { card.preferredArtworkKinds.contains($0.kind) }
    }

    // MARK: - Search results

    @ViewBuilder
    private var searchResults: some View {
        let navigationMatches = availableNavigationMatches

        if !navigationMatches.isEmpty {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                sectionTitle("Navigate")

                VStack(spacing: 0) {
                    ForEach(Array(navigationMatches.enumerated()), id: \.element.destination.id) { index, target in
                        navigationRow(target)

                        if index < navigationMatches.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }

        switch snapshot.searchState {
        case .idle, .loading:
            libraryResults(showProgress: true)

        case .content:
            libraryResults(showProgress: false)

        case .empty:
            ContentUnavailableView {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text("No library items match “\(normalizedSearchText)”.")
            }
            .frame(maxWidth: .infinity, minHeight: 260)

        case .failed:
            ContentUnavailableView {
                Label("Couldn’t Search Prismedia", systemImage: "wifi.exclamationmark")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                PrismediaButton("Try Again", variant: .prominent) {
                    Task { await retryActiveContent() }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
        }
    }

    private var availableNavigationMatches: [SearchHubNavigationTarget] {
        let allowedModeIDs = Set(modes.map(\.id))
        return SearchHubCatalog.navigationMatches(for: normalizedSearchText)
            .filter { allowedModeIDs.contains($0.mode.id) }
    }

    private func libraryResults(showProgress: Bool) -> some View {
        let sections = SearchHubCatalog.groupedResults(
            snapshot.searchResults,
            query: normalizedSearchText
        )

        return VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            if showProgress {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Updating results")
            }

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    sectionTitle(section.title)
                        .accessibilityIdentifier("shell.search.section.\(section.kind.rawValue)")
                    VStack(spacing: 0) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                            entityRow(item, identifierPrefix: "shell.search.result")

                            if index < section.items.count - 1 {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    if !showProgress && snapshot.searchTotalCount > section.items.count {
                        Divider()
                    }
                }
            }

            searchPaginationFooter
        }
    }

    @ViewBuilder
    private var searchPaginationFooter: some View {
        if snapshot.isLoadingNextSearchPage {
            ProgressView("Loading more results…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, PrismediaSpacing.large)
        } else if let message = snapshot.searchPaginationErrorMessage {
            VStack(spacing: PrismediaSpacing.medium) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                PrismediaButton("Try Again") {
                    Task { await loadNextSearchPage() }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PrismediaSpacing.medium)
        } else if snapshot.hasMoreSearchResults {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, PrismediaSpacing.large)
                .onAppear {
                    Task { await loadNextSearchPage() }
                }
                .accessibilityLabel("Loading more results")
        }
    }

    private func navigationRow(_ target: SearchHubNavigationTarget) -> some View {
        Button {
            onSelectDestination(target.mode, target.destination)
        } label: {
            HStack(spacing: PrismediaSpacing.medium) {
                Image(systemName: target.destination.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PrismediaColor.accent)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(target.destination.title)
                        .foregroundStyle(.primary)
                    Text(target.mode.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shell.search.navigation.\(target.destination.id)")
    }

    private func entityRow(_ item: EntityThumbnail, identifierPrefix: String) -> some View {
        NavigationLink(value: EntityLink(thumbnail: item)) {
            HStack(spacing: PrismediaSpacing.medium) {
                RemotePosterImage(
                    path: item.bestCoverPath,
                    fallbackSeed: item.title,
                    systemImage: systemImage(for: item.kind)
                )
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(metadataLine(for: item))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, PrismediaSpacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(metadataLine(for: item))")
        .accessibilityHint("Opens details")
        .accessibilityIdentifier("\(identifierPrefix).\(item.id.uuidString)")
    }

    private func metadataLine(for item: EntityThumbnail) -> String {
        let firstMetadata = item.meta.first?.label
        return [item.kind.displayLabel, firstMetadata]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func systemImage(for kind: EntityKind) -> String {
        SearchHubCatalog.navigationTarget(for: kind)?.destination.systemImage ?? "photo"
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
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
        guard let request = snapshot.beginSearch(query: query) else { return }

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

    // MARK: - Account

    private var accountMenu: some View {
        Menu {
            Section {
                Label(user.displayName, systemImage: "person.crop.circle")
                Text("@\(user.username)")
            }

            if user.isAdmin,
                let settings = ModeCatalog.operate.destination(id: "settings"),
                modes.contains(where: { $0.id == ModeCatalog.operate.id })
            {
                Button("Settings", systemImage: "gearshape") {
                    onSelectDestination(ModeCatalog.operate, settings)
                }
            }

            if user.allowNsfw {
                Toggle(
                    "Allow NSFW Content",
                    isOn: Binding(
                        get: { allowsNsfwContent },
                        set: onSetAllowsNsfwContent
                    )
                )
                .accessibilityIdentifier("shell.account.allowNsfw")
            }

            Divider()

            Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                onSignOut()
            }
        } label: {
            Text(accountInitials)
                .font(.caption.bold())
                .foregroundStyle(PrismediaColor.onAccent.opacity(0.82))
                .frame(width: 34, height: 34)
                .background(PrismediaColor.accent.gradient, in: Circle())
        }
        .accessibilityLabel("Account, \(user.displayName)")
        .accessibilityIdentifier("shell.account")
    }

    private var accountInitials: String {
        let parts = user.displayName
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
        let initials = parts.compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? String(user.username.prefix(1)).uppercased() : initials.uppercased()
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
            user: PrismediaPreviewData.user,
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            allowsNsfwContent: false,
            debounce: .milliseconds(10),
            onSelectMode: { _ in },
            onSelectDestination: { _, _ in },
            onSetAllowsNsfwContent: { _ in },
            onSignOut: {}
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
                SearchHubPreview()
            }
            .frame(width: 1024, height: 1366)
        }
    #elseif os(macOS)
        #Preview("Browse · macOS") {
            PreviewShell(signedIn: true) {
                SearchHubPreview()
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
