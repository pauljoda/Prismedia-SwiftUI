import SwiftUI

struct SearchHubLibraryResults: View {
    @Binding var expandedKinds: Set<EntityKind>

    let snapshot: SearchHubSnapshot
    let query: String
    let usesRegularLayout: Bool
    let topResultID: UUID?
    let showsProgress: Bool
    let onRetryPagination: () -> Void
    let onLoadNextPage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            if showsProgress {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Updating results")
            }

            ForEach(sections) { section in
                SearchHubResultGroup(
                    section: section,
                    isExpanded: expandedKinds.contains(section.kind),
                    usesRegularLayout: usesRegularLayout,
                    topResultID: topResultID
                ) {
                    toggleExpansion(for: section.kind)
                }
            }

            paginationFooter
        }
    }

    private var sections: [SearchHubResultSection] {
        SearchHubCatalog.groupedResults(snapshot.searchResults, query: query)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if snapshot.isLoadingNextSearchPage {
            ProgressView("Loading more results…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, PrismediaSpacing.large)
        } else if let message = snapshot.searchPaginationErrorMessage {
            VStack(spacing: PrismediaSpacing.medium) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                PrismediaButton("Try Again", action: onRetryPagination)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PrismediaSpacing.medium)
        } else if snapshot.hasMoreSearchResults {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, PrismediaSpacing.large)
                .onAppear(perform: onLoadNextPage)
                .accessibilityLabel("Loading more results")
        }
    }

    private func toggleExpansion(for kind: EntityKind) {
        if expandedKinds.contains(kind) {
            expandedKinds.remove(kind)
        } else {
            expandedKinds.insert(kind)
        }
    }
}

#if DEBUG
    #Preview("Search Library Results · Content") {
        @Previewable @State var expandedKinds = Set<EntityKind>()
        let query = "movie"

        ScrollView {
            SearchHubLibraryResults(
                expandedKinds: $expandedKinds,
                snapshot: SearchHubPreviewSnapshotFactory.content(query: query),
                query: query,
                usesRegularLayout: true,
                topResultID: PrismediaPreviewData.allEntities.first?.id,
                showsProgress: false,
                onRetryPagination: {},
                onLoadNextPage: {}
            )
            .padding(PrismediaSpacing.extraLarge)
        }
        .background(PrismediaBackdrop())
    }

    #Preview("Search Library Results · Updating") {
        @Previewable @State var expandedKinds = Set<EntityKind>()
        let query = "movie"

        SearchHubLibraryResults(
            expandedKinds: $expandedKinds,
            snapshot: SearchHubPreviewSnapshotFactory.loading(query: query),
            query: query,
            usesRegularLayout: false,
            topResultID: nil,
            showsProgress: true,
            onRetryPagination: {},
            onLoadNextPage: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
