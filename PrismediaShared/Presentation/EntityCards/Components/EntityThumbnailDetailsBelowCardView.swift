import SwiftUI

struct EntityThumbnailDetailsBelowCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let onPreviewHoldChanged: (Bool) -> Void
    let onPrimaryAction: (() -> Void)?
    let primaryAccessibilityHint: String?

    init(
        item: EntityThumbnail,
        layout: EntityThumbnailLayout,
        preferredWidth: CGFloat?,
        onPreviewHoldChanged: @escaping (Bool) -> Void,
        onPrimaryAction: (() -> Void)? = nil,
        primaryAccessibilityHint: String? = nil
    ) {
        self.item = item
        self.layout = layout
        self.preferredWidth = preferredWidth
        self.onPreviewHoldChanged = onPreviewHoldChanged
        self.onPrimaryAction = onPrimaryAction
        self.primaryAccessibilityHint = primaryAccessibilityHint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: artworkCaptionSpacing) {
            artworkSurface

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
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(onPrimaryAction != nil)
        }
        .padding(.bottom, PrismediaSpacing.small)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var artworkSurface: some View {
        if let onPrimaryAction {
            Button(action: onPrimaryAction) {
                artwork
                    .contentShape(Rectangle())
            }
            .prismediaEntityNavigationButtonStyle()
            .accessibilityIdentifier("entity.thumbnail.\(item.id.uuidString)")
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(primaryAccessibilityHint ?? "")
        } else {
            artwork
        }
    }

    private var artwork: some View {
        EntityThumbnailArtworkView(
            item: item,
            layout: layout,
            preferredWidth: preferredWidth,
            onPreviewHoldChanged: onPreviewHoldChanged
        )
        .prismediaCard(cornerRadius: layout == .wall || layout == .mediaOnly ? 8 : 6)
    }

    private var supportingText: String? {
        let labels = item.meta.prefix(2).map(\.label)
        guard !labels.isEmpty else { return nil }
        return labels.joined(separator: " • ")
    }

    private var artworkCaptionSpacing: CGFloat {
        #if os(tvOS)
            PrismediaSpacing.large
        #else
            PrismediaSpacing.small
        #endif
    }

    private var accessibilityLabel: String {
        var components = [item.title, item.kind.displayLabel]
        components.append(contentsOf: item.meta.map(\.label))
        if item.isFavorite { components.append("Favorite") }
        if item.isNsfw { components.append("NSFW") }
        if item.isWanted { components.append("Wanted") }
        if item.isOrganized { components.append("Organized") }
        if let rating = item.rating { components.append("\(rating) star rating") }
        return components.joined(separator: ", ")
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
