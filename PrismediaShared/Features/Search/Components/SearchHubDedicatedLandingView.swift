import SwiftUI

struct SearchHubDedicatedLandingView: View {
    @Binding var searchText: String
    @FocusState private var searchFieldFocused: Bool

    let recentItems: [EntityThumbnail]
    let recentState: SearchHubState
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            searchPrompt
            recentContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { searchFieldFocused = true }
    }

    private var searchPrompt: some View {
        VStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(PrismediaColor.accent)
                .accessibilityHidden(true)

            Text("Search your library")
                .font(.largeTitle.bold())

            Text("Find movies, series, music, books, people, and collections.")
                .font(.title3)
                .foregroundStyle(PrismediaColor.textSecondary)
                .multilineTextAlignment(.center)

            TextField("Movies, music, books, and more", text: $searchText)
                #if os(tvOS)
                    .textFieldStyle(.plain)
                #else
                    .textFieldStyle(.roundedBorder)
                #endif
                .font(.title3)
                .focused($searchFieldFocused)
                .submitLabel(.search)
                .frame(maxWidth: 620)
                .accessibilityIdentifier("shell.search.primary-field")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
        .padding(.vertical, PrismediaSpacing.extraExtraLarge)
    }

    @ViewBuilder
    private var recentContent: some View {
        switch recentState {
        case .idle, .loading:
            ProgressView("Loading recent additions…")
                .frame(maxWidth: .infinity)

        case .content:
            DashboardShelfView(
                title: "Recently Added",
                systemImage: "clock.arrow.circlepath",
                colorRole: .recent,
                items: recentItems,
                onSelect: nil
            )

        case .empty:
            ContentUnavailableView(
                "No Recent Additions",
                systemImage: "clock.arrow.circlepath",
                description: Text("New library items will appear here.")
            )
            .frame(maxWidth: .infinity, minHeight: 180)

        case .failed(let message):
            ContentUnavailableView {
                Label("Recent Additions Unavailable", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again", systemImage: "arrow.clockwise", action: onRetry)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        }
    }

}

#if DEBUG
    #Preview("Dedicated Search Landing") {
        @Previewable @State var searchText = ""

        NavigationStack {
            ScrollView {
                SearchHubDedicatedLandingView(
                    searchText: $searchText,
                    recentItems: PrismediaPreviewData.allEntities,
                    recentState: .content,
                    onRetry: {}
                )
                .padding(PrismediaSpacing.extraExtraLarge)
            }
        }
        .frame(width: 860, height: 720)
        .background(PrismediaBackdrop())
    }
#endif
