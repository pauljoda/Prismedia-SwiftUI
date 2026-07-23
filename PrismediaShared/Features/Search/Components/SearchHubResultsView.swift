import SwiftUI

struct SearchHubResultsView: View {
    @Binding var expandedKinds: Set<EntityKind>

    let snapshot: SearchHubSnapshot
    let query: String
    let navigationMatches: [SearchHubNavigationTarget]
    let usesRegularLayout: Bool
    let topResultID: UUID?
    let onSelectNavigation: (SearchHubNavigationTarget) -> Void
    let onRetrySearch: () -> Void
    let onRetryPagination: () -> Void
    let onLoadNextPage: () -> Void

    var body: some View {
        if !navigationMatches.isEmpty {
            SearchHubNavigationSection(
                matches: navigationMatches,
                onSelect: onSelectNavigation
            )
        }

        switch snapshot.searchState {
        case .idle, .loading:
            libraryResults(showsProgress: true)
        case .content:
            libraryResults(showsProgress: false)
        case .empty:
            ContentUnavailableView {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text("No library items match “\(query)”.")
            }
            .frame(maxWidth: .infinity, minHeight: SearchHubLayout.emptyStateHeight)
        case .failed:
            ContentUnavailableView {
                Label("Couldn’t Search Prismedia", systemImage: "wifi.exclamationmark")
            } description: {
                Text("Check your connection and try again.")
            } actions: {
                PrismediaButton(
                    "Try Again",
                    variant: .prominent,
                    action: onRetrySearch
                )
            }
            .frame(maxWidth: .infinity, minHeight: SearchHubLayout.errorStateHeight)
        }
    }

    private func libraryResults(showsProgress: Bool) -> some View {
        SearchHubLibraryResults(
            expandedKinds: $expandedKinds,
            snapshot: snapshot,
            query: query,
            usesRegularLayout: usesRegularLayout,
            topResultID: topResultID,
            showsProgress: showsProgress,
            onRetryPagination: onRetryPagination,
            onLoadNextPage: onLoadNextPage
        )
    }
}

#if DEBUG
    #Preview("Search Results · Empty") {
        @Previewable @State var expandedKinds = Set<EntityKind>()
        let query = "unfindable"

        SearchHubResultsView(
            expandedKinds: $expandedKinds,
            snapshot: SearchHubPreviewSnapshotFactory.empty(query: query),
            query: query,
            navigationMatches: [],
            usesRegularLayout: false,
            topResultID: nil,
            onSelectNavigation: { _ in },
            onRetrySearch: {},
            onRetryPagination: {},
            onLoadNextPage: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Results · Error") {
        @Previewable @State var expandedKinds = Set<EntityKind>()
        let query = "movie"

        SearchHubResultsView(
            expandedKinds: $expandedKinds,
            snapshot: SearchHubPreviewSnapshotFactory.failed(query: query),
            query: query,
            navigationMatches: [],
            usesRegularLayout: false,
            topResultID: nil,
            onSelectNavigation: { _ in },
            onRetrySearch: {},
            onRetryPagination: {},
            onLoadNextPage: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Results · Navigation and Content") {
        @Previewable @State var expandedKinds = Set<EntityKind>()
        let query = "movie"

        ScrollView {
            SearchHubResultsView(
                expandedKinds: $expandedKinds,
                snapshot: SearchHubPreviewSnapshotFactory.content(query: query),
                query: query,
                navigationMatches: Array(
                    SearchHubCatalog.navigationMatches(for: query).prefix(2)
                ),
                usesRegularLayout: true,
                topResultID: PrismediaPreviewData.allEntities.first?.id,
                onSelectNavigation: { _ in },
                onRetrySearch: {},
                onRetryPagination: {},
                onLoadNextPage: {}
            )
            .padding(PrismediaSpacing.extraLarge)
        }
        .background(PrismediaBackdrop())
    }
#endif
