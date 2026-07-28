import SwiftUI

struct EntityThumbnailArtworkView: View {
    @State private var artworkPalette: ArtworkPalette?

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let artworkPathOverride: String?
    let showsProgress: Bool
    let onPreviewHoldChanged: (Bool) -> Void

    init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout,
        preferredWidth: CGFloat?,
        artworkPathOverride: String? = nil,
        showsProgress: Bool = true,
        onPreviewHoldChanged: @escaping (Bool) -> Void
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.artworkPathOverride = artworkPathOverride
        self.showsProgress = showsProgress
        self.onPreviewHoldChanged = onPreviewHoldChanged
    }

    var body: some View {
        EntityThumbnailArtworkFrame(aspectRatio: aspectRatio) {
            EntityThumbnailMediaView(
                item: item,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                contentMode: artworkPresentation.contentMode,
                restingArtworkPathOverride: artworkPathOverride,
                onPreviewHoldChanged: onPreviewHoldChanged
            )
        } decoration: {
            decorations
        }
        .frame(
            width: preferredWidth,
            height: preferredWidth.map { $0 / aspectRatio }
        )
        .background(PrismediaColor.groupedContentBackground)
        .accessibilityIdentifier("entity.thumbnail.media.\(item.id.uuidString)")
        .prismediaArtworkPalette(
            for: artworkPathOverride ?? item.bestCoverPath,
            isEnabled: hasVisibleProgress,
            palette: $artworkPalette
        )
    }

    private var artworkPresentation: EntityThumbnailArtworkPresentation {
        item.thumbnailArtworkPresentation
    }

    private var aspectRatio: Double {
        layout.artworkAspectRatio(for: artworkPresentation)
    }

    private var hasVisibleProgress: Bool {
        guard showsProgress, let progress = item.progress else { return false }
        return progress > 0
    }

    private var progressTint: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }

    private var overlayPolicy: EntityThumbnailOverlayPolicy {
        EntityThumbnailOverlayPolicy(item: item)
    }

    private var decorations: some View {
        Color.clear
            .overlay(alignment: .bottomLeading) {
                if showsProgress, let progress = item.progress, progress > 0 {
                    progressMeter(progress)
                }
            }
            .overlay(alignment: .topTrailing) {
                if layout.showsArtworkBadges, !overlayPolicy.topTrailing.isEmpty {
                    EntityThumbnailBadgeRow(badges: overlayPolicy.topTrailing)
                        .padding(PrismediaSpacing.small)
                        .padding(.trailing, topTrailingActionPadding)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if layout.showsArtworkBadges, !overlayPolicy.bottomLeading.isEmpty {
                    EntityThumbnailBadgeRow(badges: overlayPolicy.bottomLeading)
                        .padding(PrismediaSpacing.small)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if layout.showsArtworkBadges, !overlayPolicy.bottomTrailing.isEmpty {
                    EntityThumbnailBadgeRow(badges: overlayPolicy.bottomTrailing)
                        .padding(PrismediaSpacing.small)
                }
            }
    }

    private var topTrailingActionPadding: CGFloat {
        EntityThumbnailInteractionPolicy(item: item, layout: layout).showsContextMenu
            ? PrismediaLayout.minimumHitTarget
            : 0
    }

    private func progressMeter(_ value: Double) -> some View {
        VStack {
            Spacer()
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(PrismediaColor.background.opacity(0.5))
                Rectangle()
                    .fill(progressTint)
                    .scaleEffect(x: CGFloat(min(1, max(0, value))), y: 1, anchor: .leading)
            }
            .frame(height: 3)
        }
    }
}

extension EntityThumbnailLayout {
    fileprivate var showsArtworkBadges: Bool {
        self != .compact
    }
}

#if DEBUG
    #Preview("Thumbnail Artwork and Decorations") {
        PreviewShell {
            EntityThumbnailArtworkView(
                item: PrismediaPreviewData.videos[0],
                layout: .grid,
                preferredWidth: 300,
                onPreviewHoldChanged: { _ in }
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
