import SwiftUI

struct EntityThumbnailArtworkView: View {
    @State private var artworkPalette: ArtworkPalette?

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let showsProgress: Bool
    let onPreviewHoldChanged: (Bool) -> Void

    init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout,
        preferredWidth: CGFloat?,
        showsProgress: Bool = true,
        onPreviewHoldChanged: @escaping (Bool) -> Void
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.showsProgress = showsProgress
        self.onPreviewHoldChanged = onPreviewHoldChanged
    }

    var body: some View {
        EntityThumbnailArtworkFrame(aspectRatio: aspectRatio) {
            EntityThumbnailMediaView(
                item: item,
                systemImage: item.kind.thumbnailFallbackSystemImage,
                contentMode: artworkPresentation.contentMode,
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
            for: item.bestCoverPath,
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

    private var cardPresentation: EntityThumbnailCardPresentation {
        EntityThumbnailCardPresentation(item: item, layout: layout)
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
            .overlay(alignment: .topLeading) {
                if cardPresentation.showsArtworkBadges,
                    !cardPresentation.usesArtworkExtension
                {
                    badgeRow(overlayPolicy.topLeading)
                        .padding(PrismediaSpacing.small)
                }
            }
            .overlay(alignment: .topTrailing) {
                if cardPresentation.showsArtworkBadges {
                    badgeRow(overlayPolicy.topTrailing)
                        .padding(PrismediaSpacing.small)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if cardPresentation.showsArtworkBadges {
                    badgeRow(overlayPolicy.bottomTrailing)
                        .padding(PrismediaSpacing.small)
                }
            }
    }

    private func badgeRow(_ badges: [EntityThumbnailBadgePresentation]) -> some View {
        HStack(spacing: PrismediaSpacing.small) {
            ForEach(badges, id: \.kind) { badge in
                ThumbnailBadge(
                    systemImage: badge.systemImage,
                    label: badge.label,
                    tint: badgeTint(badge.tone),
                    background: badgeBackground(badge.tone),
                    iconAfterLabel: badge.kind == .rating
                )
            }
        }
    }

    private func badgeTint(_ tone: EntityThumbnailBadgeTone) -> Color {
        switch tone {
        case .accent, .downloading, .attention: PrismediaColor.accent
        case .searching, .cleanup: PrismediaColor.warning
        case .queued, .muted: PrismediaColor.textSecondary
        case .failed, .danger: PrismediaColor.destructive
        case .success: PrismediaColor.success
        }
    }

    private func badgeBackground(_ tone: EntityThumbnailBadgeTone) -> Color {
        switch tone {
        case .accent, .downloading, .attention:
            PrismediaColor.accent.opacity(PrismediaOpacity.statusFill)
        case .searching, .cleanup:
            PrismediaColor.warning.opacity(PrismediaOpacity.statusFill)
        case .queued, .muted:
            PrismediaColor.controlFill
        case .failed, .danger:
            PrismediaColor.destructive.opacity(PrismediaOpacity.statusFill)
        case .success:
            PrismediaColor.success.opacity(PrismediaOpacity.statusFill)
        }
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
