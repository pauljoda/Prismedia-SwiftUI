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
            outputAspectRatio: cardAspectRatio,
            isEnabled: !reduceTransparency
        )
        .overlay {
            GeometryReader { proxy in
                let artworkHeight = min(
                    proxy.size.height,
                    proxy.size.width / item.thumbnailArtworkPresentation.aspectRatio
                )

                ZStack(alignment: .top) {
                    EntityThumbnailArtworkView(
                        item: item,
                        layout: layout,
                        preferredWidth: preferredWidth,
                        showsProgress: false,
                        onPreviewHoldChanged: onPreviewHoldChanged
                    )
                    .frame(width: proxy.size.width, height: artworkHeight)

                    metadata
                        .frame(width: proxy.size.width, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let progress = item.progress, progress > 0 {
                progressMeter(progress)
            }
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .background(PrismediaColor.groupedContentBackground)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .prismediaCard(cornerRadius: layout == .wall ? 8 : 6)
        .prismediaArtworkPalette(
            for: item.bestCoverPath,
            isEnabled: paletteLoadingEnabled,
            palette: $artworkPalette
        )
    }

    private var cardAspectRatio: Double {
        EntityThumbnailCardPresentation.artworkFadeAspectRatio(
            for: item.thumbnailArtworkPresentation.aspectRatio
        )
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
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Text(item.title)
                .font(PrismediaTypography.cardTitle)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            metadataActionRow(limit: 3)
        }
        .foregroundStyle(PrismediaColor.onMedia)
        .padding(.leading, PrismediaSpacing.small)
        .padding(.trailing, metadataTrailingPadding)
        .padding(.top, PrismediaSpacing.extraSmall)
        .padding(.bottom, metadataBottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                if reduceTransparency {
                    PrismediaColor.groupedContentBackground
                }
                legibilityGradient
                accessibilityScrim
            }
        }
        .shadow(color: PrismediaColor.background.opacity(0.7), radius: 2, y: 1)
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

    private var metadataTrailingPadding: CGFloat {
        PrismediaSpacing.small
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
    #Preview("Artwork Fade Cards · Stable Artwork") {
        PreviewShell {
            HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                EntityThumbnailLandscapeCardView(
                    item: EntityThumbnail(
                        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
                        kind: .video,
                        title: "Pilot",
                        parentKind: .videoSeason,
                        sortOrder: 6,
                        coverURL: "/preview/video-1.jpg",
                        meta: [
                            EntityThumbnailMeta(icon: "duration", label: "43:22"),
                            EntityThumbnailMeta(icon: "resolution", label: "4K"),
                        ],
                        hasSourceMedia: true
                    ),
                    layout: .grid,
                    preferredWidth: 220,
                    onPreviewHoldChanged: { _ in }
                )

                EntityThumbnailLandscapeCardView(
                    item: EntityThumbnail(
                        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
                        kind: .video,
                        title: "Beware the Second Beating",
                        parentKind: .videoSeason,
                        sortOrder: 7,
                        coverURL: "/preview/video-1.jpg",
                        meta: [
                            EntityThumbnailMeta(icon: "duration", label: "43:22"),
                            EntityThumbnailMeta(icon: "resolution", label: "4K"),
                        ],
                        hasSourceMedia: true
                    ),
                    layout: .grid,
                    preferredWidth: 220,
                    onPreviewHoldChanged: { _ in }
                )

                EntityThumbnailLandscapeCardView(
                    item: PrismediaPreviewData.series,
                    layout: .grid,
                    preferredWidth: 180,
                    onPreviewHoldChanged: { _ in }
                )
            }
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
