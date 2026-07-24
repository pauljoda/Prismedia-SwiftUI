import SwiftUI

struct EntityThumbnailDetailsBelowCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let onPreviewHoldChanged: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            EntityThumbnailArtworkView(
                item: item,
                layout: layout,
                preferredWidth: preferredWidth,
                onPreviewHoldChanged: onPreviewHoldChanged
            )
            .prismediaCard(cornerRadius: layout == .wall || layout == .mediaOnly ? 8 : 6)

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                Text(item.title)
                    .font(PrismediaTypography.cardTitle)
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)

                if let supportingText {
                    Text(supportingText)
                        .font(PrismediaTypography.metadata)
                        .foregroundStyle(PrismediaColor.textMuted)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
            }
            .padding(.horizontal, PrismediaSpacing.extraSmall)
            .padding(.trailing, contextMenuTrailingPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var supportingText: String? {
        let labels = item.meta.prefix(2).map(\.label)
        guard !labels.isEmpty else { return nil }
        return labels.joined(separator: " • ")
    }

    private var contextMenuTrailingPadding: CGFloat {
        EntityThumbnailInteractionPolicy(item: item, layout: layout).showsContextMenu
            ? PrismediaLayout.minimumHitTarget
            : 0
    }
}

#if DEBUG
    #Preview("Entity Card · Text Below Artwork") {
        PreviewShell {
            HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                EntityThumbnailDetailsBelowCardView(
                    item: PrismediaPreviewData.series,
                    layout: .grid,
                    preferredWidth: 180,
                    onPreviewHoldChanged: { _ in }
                )

                EntityThumbnailDetailsBelowCardView(
                    item: PrismediaPreviewData.videos[0],
                    layout: .grid,
                    preferredWidth: 220,
                    onPreviewHoldChanged: { _ in }
                )
            }
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }
#endif
