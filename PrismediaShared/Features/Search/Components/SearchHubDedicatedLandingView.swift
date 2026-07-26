import SwiftUI

struct SearchHubDedicatedLandingView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        .padding(.vertical, PrismediaSpacing.extraExtraLarge)
    }

    @ViewBuilder
    private var recentContent: some View {
        switch recentState {
        case .idle, .loading:
            ProgressView("Loading recent additions…")
                .frame(maxWidth: .infinity)

        case .content:
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Label("Recently Added", systemImage: "clock.arrow.circlepath")
                    .font(.title2.bold())

                LazyVGrid(columns: recentColumns, spacing: PrismediaSpacing.small) {
                    ForEach(recentItems.prefix(12)) { item in
                        recentItem(item)
                    }
                }
            }

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

    private var recentColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: PrismediaSpacing.large),
            count: count
        )
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
