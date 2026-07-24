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
        EntityThumbnailArtworkExtensionView(
            item: item,
            outputAspectRatio: presentation.cardAspectRatio,
            isEnabled: !reduceTransparency
        )
        .overlay {
            GeometryReader { proxy in
                let artworkHeight = min(
                    proxy.size.height,
                    proxy.size.width / item.thumbnailArtworkPresentation.aspectRatio
                )

                VStack(spacing: 0) {
                    EntityThumbnailArtworkView(
                        item: item,
                        layout: layout,
                        preferredWidth: preferredWidth,
                        showsProgress: false,
                        onPreviewHoldChanged: onPreviewHoldChanged
                    )
                    .frame(width: proxy.size.width, height: artworkHeight)

                    metadata
                        .frame(
                            width: proxy.size.width,
                            height: max(0, proxy.size.height - artworkHeight),
                            alignment: .topLeading
                        )
                        .clipped()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let progress = item.progress, progress > 0 {
                progressMeter(progress)
            }
        }
        .aspectRatio(presentation.cardAspectRatio, contentMode: .fit)
        .background(PrismediaColor.groupedContentBackground)
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
        .padding(.trailing, metadataTrailingPadding)
        .padding(.top, PrismediaSpacing.extraSmall)
        .padding(.bottom, metadataBottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                legibilityGradient
                accessibilityScrim
            }
        }
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

        }
    }

    @ViewBuilder
    private func metadataActionRow(limit: Int) -> some View {
        if !item.meta.isEmpty {
            metadataChipRow(limit: limit)
        }
    }

    private func metadataChipRow(limit: Int) -> some View {
        MetaChipRow(meta: Array(item.meta.prefix(limit)))
    }

    private var contextChip: some View {
        PrismediaGlassStatusChip(
            contextBadge.label,
            systemImage: contextBadge.systemImage,
            tint: PrismediaColor.background,
            size: .thumbnail
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

    private var metadataTrailingPadding: CGFloat {
        let basePadding = PrismediaSpacing.small
        return showsContextMenu
            ? PrismediaLayout.minimumHitTarget + basePadding
            : basePadding
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

    private func progressMeter(_ value: Double) -> some View {
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
