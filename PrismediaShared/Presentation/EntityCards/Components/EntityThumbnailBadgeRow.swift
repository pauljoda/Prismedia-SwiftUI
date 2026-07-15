import SwiftUI

struct EntityThumbnailBadgeRow: View {
    let badges: [EntityThumbnailBadgePresentation]

    var body: some View {
        HStack(spacing: PrismediaSpacing.small) {
            ForEach(badges, id: \.kind) { badge in
                ThumbnailBadge(
                    systemImage: badge.systemImage,
                    label: badge.label,
                    tint: tint(for: badge.tone),
                    background: background(for: badge.tone),
                    iconAfterLabel: badge.kind == .rating
                )
            }
        }
    }

    private func tint(for tone: EntityThumbnailBadgeTone) -> Color {
        switch tone {
        case .accent, .downloading, .attention: PrismediaColor.accent
        case .searching, .cleanup: PrismediaColor.warning
        case .queued, .muted: PrismediaColor.textSecondary
        case .failed, .danger: PrismediaColor.destructive
        case .success: PrismediaColor.success
        }
    }

    private func background(for tone: EntityThumbnailBadgeTone) -> Color {
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
#endif
