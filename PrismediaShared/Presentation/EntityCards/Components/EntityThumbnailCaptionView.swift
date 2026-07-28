import SwiftUI

struct EntityThumbnailCaptionView: View {
    #if os(tvOS)
        @ScaledMetric(relativeTo: .subheadline) private var captionHeight: CGFloat = 76
    #else
        @ScaledMetric(relativeTo: .subheadline) private var captionHeight: CGFloat = 54
    #endif

    let item: EntityThumbnail
    let subtitle: String?
    let horizontalPadding: CGFloat

    init(
        item: EntityThumbnail,
        subtitle: String? = nil,
        horizontalPadding: CGFloat = PrismediaSpacing.extraSmall
    ) {
        self.item = item
        self.subtitle = subtitle ?? item.subtitle
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
            Text(item.title)
                .font(PrismediaTypography.cardTitle)
                .foregroundStyle(PrismediaColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            secondarySlot
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: captionHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .clipped()
    }

    private var secondarySlot: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
            if let subtitle = normalizedSubtitle {
                Text(subtitle)
                    .font(PrismediaTypography.compactCaption)
                    .foregroundStyle(PrismediaColor.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !item.meta.isEmpty {
                MetaChipRow(meta: item.meta)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var normalizedSubtitle: String? {
        guard let subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines),
            !subtitle.isEmpty
        else { return nil }
        return subtitle
    }
}

#if DEBUG
    #Preview("Entity Thumbnail Caption · Hierarchy and Chips") {
        EntityThumbnailCaptionView(
            item: EntityThumbnail(
                id: UUID(),
                kind: .videoSeason,
                title: "A Season Title That Is Far Too Long for Its Thumbnail",
                subtitle: "A Series Title That Also Needs Bounded Space",
                meta: [
                    EntityThumbnailMeta(icon: "video", label: "12 episodes"),
                    EntityThumbnailMeta(icon: "resolution", label: "4K"),
                ]
            )
        )
        .frame(width: 180)
        .padding()
        .background(PrismediaBackdrop())
    }
#endif
