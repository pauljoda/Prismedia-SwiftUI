import SwiftUI

#if os(tvOS)
    struct TVSeasonBoundaryCard: View {
        let season: EntityThumbnail
        let direction: TVSeasonBoundaryDirection

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Image(systemName: direction.symbolName)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(PrismediaColor.accent)

                Spacer(minLength: 0)

                Text(direction.title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(season.title)
                    .font(.subheadline)
                    .foregroundStyle(PrismediaColor.onMedia.opacity(0.72))
                    .lineLimit(1)
            }
            .padding(PrismediaSpacing.large)
            .frame(width: 300, height: 169, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous)
                    .fill(PrismediaColor.elevatedContentBackground)
            }
            .contentShape(Rectangle())
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Season Boundary Card · Previous") {
        PreviewShell {
            TVSeasonBoundaryCard(
                season: TVSeasonsPreviewData.seasonThumbnail,
                direction: .previous
            )
        }
    }
#endif
