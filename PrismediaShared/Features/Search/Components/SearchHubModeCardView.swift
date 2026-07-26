import SwiftUI

struct SearchHubModeCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let card: SearchHubModeCard
    let artwork: EntityThumbnail?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: cardHeight)
                .background {
                    RemotePosterImage(
                        path: artwork?.bestCoverPath,
                        fallbackSeed: artwork?.title ?? card.title,
                        fallbackColors: orderedFallbackColors,
                        systemImage: card.systemImage
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                .overlay {
                    ZStack {
                        LinearGradient(
                            colors: orderedFallbackColors.map { $0.opacity(0.18) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

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
                .clipShape(cardShape)
                .contentShape(cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.title). \(card.subtitle)")
        .accessibilityHint("Opens the \(card.title) section")
        .accessibilityIdentifier("shell.search.mode.\(card.id)")
    }

    private var cardHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? SearchHubLayout.accessibilityModeCardHeight
            : SearchHubLayout.compactModeCardHeight
    }

    private var cardShape: PrismediaStableRoundedRectangle {
        PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.card)
    }

    private var orderedFallbackColors: [Color] {
        let index = ModeCatalog.all.firstIndex { $0.id == card.id } ?? 0
        return PrismediaColor.materialSpectrumPair(at: index)
    }
}

#if DEBUG
    #Preview("Search Mode Card · Artwork") {
        SearchHubModeCardView(
            card: SearchHubCatalog.card(for: ModeCatalog.video),
            artwork: PrismediaPreviewData.videos.first,
            onSelect: {}
        )
        .frame(width: SearchHubLayout.maximumModeCardWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Mode Card · Fallback") {
        SearchHubModeCardView(
            card: SearchHubCatalog.card(for: ModeCatalog.books),
            artwork: nil,
            onSelect: {}
        )
        .frame(width: SearchHubLayout.minimumModeCardWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Search Mode Card · Accessibility") {
        SearchHubModeCardView(
            card: SearchHubCatalog.card(for: ModeCatalog.browse),
            artwork: PrismediaPreviewData.allEntities.first,
            onSelect: {}
        )
        .frame(width: SearchHubLayout.maximumModeCardWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
