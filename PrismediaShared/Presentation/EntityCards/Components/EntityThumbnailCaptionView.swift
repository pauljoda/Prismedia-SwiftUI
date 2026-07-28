import SwiftUI

struct EntityThumbnailCaptionView: View {
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
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .clipped()
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
                    EntityThumbnailMeta(icon: "episode", label: "12"),
                    EntityThumbnailMeta(icon: "resolution", label: "4K"),
                ]
            )
        )
        .frame(width: 180)
        .padding()
        .background(PrismediaBackdrop())
    }
#endif
