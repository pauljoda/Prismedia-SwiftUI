import SwiftUI

struct EntityThumbnailBadgeRow: View {
    let badges: [EntityThumbnailBadgePresentation]

    var body: some View {
        GlassEffectContainer(spacing: PrismediaSpacing.small) {
            HStack(spacing: PrismediaSpacing.small) {
                ForEach(badges, id: \.kind) { badge in
                    PrismediaGlassStatusChip(
                        badge.label,
                        systemImage: badge.systemImage,
                        tint: tint(for: badge.tone),
                        size: .thumbnail,
                        iconAfterTitle: badge.kind == .rating
                    )
                }
            }
        }
    }

    private func tint(for tone: EntityThumbnailBadgeTone) -> Color? {
        switch tone {
        case .accent: PrismediaColor.mediaOverlayGlassTint
        case .downloading: PrismediaColor.spectrumBlue
        case .attention: PrismediaColor.warning
        case .searching, .cleanup: PrismediaColor.warning
        case .queued, .muted: PrismediaColor.mediaOverlayGlassTint
        case .failed, .danger: PrismediaColor.destructive
        case .success: PrismediaColor.success
        }
    }
}

#if DEBUG
    #Preview("Thumbnail Status Badges") {
        EntityThumbnailBadgeRow(
            badges: EntityThumbnailOverlayPolicy(
                item: PrismediaPreviewData.videos[1]
            ).topTrailing
        )
        .padding(PrismediaSpacing.large)
        .background(PrismediaBackdrop())
    }

    #Preview("Thumbnail Wanted Badge · Bright and Dark Artwork") {
        HStack(spacing: PrismediaSpacing.large) {
            EntityThumbnailBadgeRow(
                badges: [
                    .init(
                        kind: .wanted,
                        label: "Wanted",
                        systemImage: "bookmark.fill",
                        tone: .muted
                    )
                ]
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(Color.white)

            EntityThumbnailBadgeRow(
                badges: [
                    .init(
                        kind: .wanted,
                        label: "Wanted",
                        systemImage: "bookmark.fill",
                        tone: .muted
                    )
                ]
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(Color.black)
        }
    }
#endif
