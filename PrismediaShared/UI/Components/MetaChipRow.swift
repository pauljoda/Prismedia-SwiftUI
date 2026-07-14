import SwiftUI

public struct MetaChipRow: View {
    let meta: [EntityThumbnailMeta]

    public init(meta: [EntityThumbnailMeta]) {
        self.meta = meta
    }

    public var body: some View {
        let metrics = MetaChipMetrics.compact

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: metrics.rowSpacing) {
                ForEach(Array(meta.prefix(5)), id: \.self) { item in
                    HStack(spacing: metrics.contentSpacing) {
                        Image(systemName: symbol(for: item.icon))
                            .font(PrismediaTypography.compactCaption)
                            .imageScale(.small)
                            .foregroundStyle(PrismediaColor.accent)
                        Text(item.label)
                            .font(PrismediaTypography.badge)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.vertical, metrics.verticalPadding)
                    .background(PrismediaColor.controlFill.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous)
                            .stroke(PrismediaColor.border, lineWidth: PrismediaLayout.hairline)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))
                }
            }
        }
    }

    private func symbol(for icon: String) -> String {
        switch icon {
        case "duration", "clock": return "clock"
        case "resolution": return "rectangle"
        case "video": return "film"
        case "image", "gallery": return "photo"
        case "person": return "person.2"
        case "progress": return "gauge.with.dots.needle.bottom.50percent"
        case "codec", "format": return "film"
        case "folder": return "folder"
        case "book": return "book"
        default: return "square.grid.2x2"
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
