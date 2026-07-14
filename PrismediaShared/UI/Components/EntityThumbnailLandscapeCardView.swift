import SwiftUI

struct EntityThumbnailLandscapeCardView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var artworkPalette: ArtworkPalette?

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let onPreviewHoldChanged: (Bool) -> Void

    var body: some View {
        Color.clear
            .aspectRatio(presentation.cardAspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        PrismediaColor.groupedContentBackground

                        artwork(
                            width: geometry.size.width,
                            cardHeight: geometry.size.height
                        )

                        metadata

                        if let progress = item.progress, progress > 0 {
                            progressMeter(progress)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .prismediaCard(cornerRadius: layout == .wall ? 8 : 6)
            .prismediaArtworkPalette(
                for: item.bestCoverPath,
                isEnabled: paletteLoadingEnabled,
                palette: $artworkPalette
            )
    }

    private var presentation: EntityThumbnailCardPresentation {
        EntityThumbnailCardPresentation(item: item, layout: layout)
    }

    @ViewBuilder
    private func artwork(width: CGFloat, cardHeight: CGFloat) -> some View {
        #if os(tvOS)
            RemotePosterImage(
                path: item.bestCoverPath,
                fallbackSeed: item.title,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                contentMode: .fill,
                maxPixelSize: 512
            )
            .frame(width: width, height: cardHeight)
            .overlay(legibilityGradient)
            .overlay(accessibilityScrim)
            .clipped()
            .accessibilityIdentifier("entity.thumbnail.media.\(item.id.uuidString)")
        #else
            continuationArtwork(width: width, cardHeight: cardHeight)
            sharpArtwork(width: width)
        #endif
    }

    #if !os(tvOS)
        private func continuationArtwork(width: CGFloat, cardHeight: CGFloat) -> some View {
            RemotePosterImage(
                path: item.bestCoverPath,
                fallbackSeed: item.title,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                contentMode: .fill,
                maxPixelSize: 384
            )
            .frame(width: width, height: cardHeight)
            .scaleEffect(1.08)
            .blur(radius: reduceTransparency ? 0 : 16)
            .overlay(legibilityGradient)
            .overlay(accessibilityScrim)
            .clipped()
            .accessibilityHidden(true)
        }

        private var artworkFade: some View {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.56),
                    .init(color: .black.opacity(0.9), location: 0.72),
                    .init(color: .black.opacity(0.48), location: 0.9),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        private func sharpArtwork(width: CGFloat) -> some View {
            RemotePosterImage(
                path: item.bestCoverPath,
                fallbackSeed: item.title,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                contentMode: item.thumbnailArtworkPresentation.contentMode,
                maxPixelSize: 512
            )
            .frame(width: width, height: artworkHeight(for: width))
            .clipped()
            .mask(artworkFade)
            .accessibilityIdentifier("entity.thumbnail.media.\(item.id.uuidString)")
        }
    #endif

    private var legibilityGradient: some View {
        LinearGradient(
            colors: [
                .clear,
                PrismediaColor.background.opacity(0.08),
                PrismediaColor.background.opacity(0.18),
                PrismediaColor.background.opacity(0.28),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var accessibilityScrim: some View {
        PrismediaColor.background.opacity(
            reduceTransparency
                ? 0.5
                : colorSchemeContrast == .increased ? 0.2 : 0.04
        )
    }

    private var metadata: some View {
        ViewThatFits(in: .vertical) {
            detailedMetadata
            compactMetadata
            titleOnlyMetadata
        }
        .padding(.leading, PrismediaSpacing.small)
        .padding(.trailing, PrismediaSpacing.small)
        .padding(.top, PrismediaSpacing.extraSmall)
        .padding(.bottom, metadataBottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .shadow(color: PrismediaColor.background.opacity(0.7), radius: 2, y: 1)
    }

    private var detailedMetadata: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            contextChip

            Text(item.title)
                .font(PrismediaTypography.cardTitle)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let summary = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
                !summary.isEmpty
            {
                Text(summary)
                    .font(PrismediaTypography.compactCaption)
                    .foregroundStyle(PrismediaColor.onMedia.opacity(0.84))
                    .lineLimit(2)
            }

            metadataActionRow(limit: 3)
        }
        .foregroundStyle(PrismediaColor.onMedia)
    }

    private var compactMetadata: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            contextChip

            Text(item.title)
                .font(PrismediaTypography.captionEmphasized)
                .foregroundStyle(PrismediaColor.onMedia)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            metadataActionRow(limit: 2)
        }
    }

    private var titleOnlyMetadata: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text(item.title)
                .font(PrismediaTypography.captionEmphasized)
                .foregroundStyle(PrismediaColor.onMedia)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsContextMenu {
                contextMenuRowSpacer
            }
        }
    }

    @ViewBuilder
    private func metadataActionRow(limit: Int) -> some View {
        if !item.meta.isEmpty {
            metadataChipRow(limit: limit)
        } else if showsContextMenu {
            contextMenuRowSpacer
        }
    }

    private var contextMenuRowSpacer: some View {
        Color.clear
            .frame(height: PrismediaSpacing.large)
            .accessibilityHidden(true)
    }

    private func metadataChipRow(limit: Int) -> some View {
        MetaChipRow(meta: Array(item.meta.prefix(limit)))
            .padding(.trailing, metadataActionTrailingPadding)
    }

    private var contextChip: some View {
        ThumbnailBadge(
            systemImage: contextBadge.systemImage,
            label: contextBadge.label,
            tint: PrismediaColor.onMedia,
            background: PrismediaColor.background.opacity(0.68),
            iconAfterLabel: false
        )
    }

    private var contextBadge: EntityThumbnailBadgePresentation {
        EntityThumbnailOverlayPolicy(item: item).topLeading.first
            ?? EntityThumbnailBadgePresentation(
                kind: .position,
                label: item.kind.displayLabel,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                tone: .muted
            )
    }

    private var showsContextMenu: Bool {
        EntityThumbnailInteractionPolicy(item: item, layout: layout).showsContextMenu
    }

    private var metadataActionTrailingPadding: CGFloat {
        showsContextMenu
            ? PrismediaLayout.minimumHitTarget + PrismediaSpacing.small
            : 0
    }

    private var metadataBottomPadding: CGFloat {
        hasVisibleProgress ? PrismediaSpacing.small : PrismediaSpacing.extraSmall
    }

    private var hasVisibleProgress: Bool {
        guard let progress = item.progress else { return false }
        return progress > 0
    }

    private var paletteLoadingEnabled: Bool {
        #if os(tvOS)
            false
        #else
            hasVisibleProgress
        #endif
    }

    private var progressTint: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }

    private func artworkHeight(for width: CGFloat) -> CGFloat {
        width / item.thumbnailArtworkPresentation.aspectRatio
    }

    private func progressMeter(_ value: Double) -> some View {
        VStack {
            Spacer()
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(PrismediaColor.background.opacity(0.54))
                Rectangle()
                    .fill(progressTint)
                    .scaleEffect(
                        x: CGFloat(min(1, max(0, value))),
                        y: 1,
                        anchor: .leading
                    )
            }
            .frame(height: 3)
        }
    }
}

#if DEBUG
    #Preview("Extended Landscape Card") {
        PreviewShell {
            EntityThumbnailLandscapeCardView(
                item: PrismediaPreviewData.videos[0],
                layout: .grid,
                preferredWidth: 320,
                onPreviewHoldChanged: { _ in }
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
