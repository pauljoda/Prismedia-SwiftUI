import SwiftUI

struct SearchHubBrowseGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let modes: [AppMode]
    let recentItems: [EntityThumbnail]
    let onSelectMode: (AppMode) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: PrismediaSpacing.medium) {
            ForEach(SearchHubCatalog.cards(for: modes)) { card in
                SearchHubModeCardView(
                    card: card,
                    artwork: representativeArtwork(for: card)
                ) {
                    onSelectMode(card.mode)
                }
            }
        }
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: PrismediaSpacing.medium)]
        }

        if horizontalSizeClass == .compact {
            return [
                GridItem(.flexible(), spacing: PrismediaSpacing.medium),
                GridItem(.flexible(), spacing: PrismediaSpacing.medium),
            ]
        }

        return [
            GridItem(
                .adaptive(
                    minimum: SearchHubLayout.minimumModeCardWidth,
                    maximum: SearchHubLayout.maximumModeCardWidth
                ),
                spacing: PrismediaSpacing.medium
            )
        ]
    }

    private func representativeArtwork(for card: SearchHubModeCard) -> EntityThumbnail? {
        recentItems.first { card.preferredArtworkKinds.contains($0.kind) }
    }
}

#if DEBUG
    #Preview("Search Browse Grid · Content") {
        SearchHubBrowseGrid(
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            recentItems: PrismediaPreviewData.allEntities,
            onSelectMode: { _ in }
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Browse Grid · Empty Artwork") {
        SearchHubBrowseGrid(
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            recentItems: [],
            onSelectMode: { _ in }
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Browse Grid · Accessibility") {
        SearchHubBrowseGrid(
            modes: ModeCatalog.modes(for: PrismediaPreviewData.user),
            recentItems: PrismediaPreviewData.allEntities,
            onSelectMode: { _ in }
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
