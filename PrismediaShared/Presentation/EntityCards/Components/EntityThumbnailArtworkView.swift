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
            EntityArtworkSurfaceView(surface: artworkPresentation.surface) {
                EntityThumbnailMediaView(
                    item: item,
                    systemImage: item.kind.thumbnailFallbackSystemImage,
                    contentMode: artworkPresentation.contentMode,
                    restingArtworkPathOverride: artworkPathOverride,
                    onPreviewHoldChanged: onPreviewHoldChanged
                )
            }
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
        showsProgress && progressMeters.isVisible
    }

    private var progressMeters: EntityThumbnailProgressMeters {
        EntityThumbnailProgressMeters(item: item)
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
                if showsProgress {
                    progressMeter(progressMeters)
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

    @ViewBuilder
    private func progressMeter(_ meters: EntityThumbnailProgressMeters) -> some View {
        switch meters {
        case .none:
            EmptyView()
        case .single(let value):
            VStack {
                Spacer()
                meterTrack(value, fill: progressTint, height: 3)
            }
        case .separate(let reading, let listening):
            // A Separate Book draws reading over listening so the two never read as one number;
            // listening keeps the same paint at a quieter weight.
            VStack(spacing: 1) {
                Spacer()
                meterTrack(reading, fill: progressTint, height: 2)
                meterTrack(listening, fill: progressTint.opacity(PrismediaOpacity.secondaryMeter), height: 2)
            }
        }
    }

    private func meterTrack(_ value: Double, fill: Color, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(PrismediaColor.background.opacity(0.5))
            Rectangle()
                .fill(fill)
                .scaleEffect(x: CGFloat(min(1, max(0, value))), y: 1, anchor: .leading)
        }
        .frame(height: height)
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

    #Preview("Thumbnail Artwork · Separate Book Progress") {
        PreviewShell {
            EntityThumbnailArtworkView(
                item: EntityThumbnail(
                    id: UUID(),
                    kind: .book,
                    title: "The Quiet Frequency",
                    progress: 0.42,
                    progressSeparate: true,
                    listeningProgress: 0.18
                ),
                layout: .grid,
                preferredWidth: 220,
                onPreviewHoldChanged: { _ in }
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
