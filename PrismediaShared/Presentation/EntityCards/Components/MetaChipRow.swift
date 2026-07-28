import SwiftUI

public struct MetaChipRow: View {
    let meta: [EntityThumbnailMeta]

    public init(meta: [EntityThumbnailMeta]) {
        self.meta = meta
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            chipRow(limit: 5)
            chipRow(limit: 4)
            chipRow(limit: 3)
            chipRow(limit: 2)
            chipRow(limit: 1, fillsAvailableWidth: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    private func chipRow(limit: Int, fillsAvailableWidth: Bool = false) -> some View {
        let metrics = MetaChipMetrics.compact

        return HStack(spacing: metrics.rowSpacing) {
            ForEach(Array(meta.prefix(limit)), id: \.self) { item in
                HStack(spacing: metrics.contentSpacing) {
                    Image(systemName: item.thumbnailSystemImage)
                        .font(PrismediaTypography.compactCaption)
                        .imageScale(.small)
                        .foregroundStyle(item.thumbnailTint)
                    Text(item.label)
                        .font(PrismediaTypography.badge)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(
                            maxWidth: fillsAvailableWidth ? .infinity : nil,
                            alignment: .leading
                        )
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.vertical, metrics.verticalPadding)
                .frame(
                    maxWidth: fillsAvailableWidth ? .infinity : nil,
                    alignment: .leading
                )
                .background(item.thumbnailTint.opacity(0.11))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous)
                        .stroke(item.thumbnailTint.opacity(0.32), lineWidth: PrismediaLayout.hairline)
                }
                .compositingGroup()
                .clipShape(.rect(cornerRadius: PrismediaRadius.badge, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.thumbnailAccessibilityLabel)
            }
        }
    }
}

#if DEBUG
    #Preview("Meta Chips") {
        PreviewShell {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                MetaChipRow(meta: PrismediaPreviewData.videos[0].meta)
                MetaChipRow(meta: PrismediaPreviewData.book.meta)
            }
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }
#endif
