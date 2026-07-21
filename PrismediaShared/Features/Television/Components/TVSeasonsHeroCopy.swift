import SwiftUI

#if os(tvOS)

    struct TVSeasonsHeroCopy: View {
        let series: EntityDetail
        let selectedEpisode: EntityThumbnail?
        let selectedEpisodeDetail: EntityDetail?
        let seasons: [EntityThumbnail]
        let selectedSeasonID: UUID?

        var body: some View {
            let seriesPresentation = EntityDetailPresentation(detail: series)
            let description = TVEpisodeDescriptionPresentation.text(
                episode: selectedEpisode,
                episodeDetail: selectedEpisodeDetail,
                seriesDescription: seriesPresentation.description
            )

            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Text(series.title)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(PrismediaColor.accent)
                    .lineLimit(1, reservesSpace: true)

                Text(selectedEpisode.map(episodeSubtitle) ?? " ")
                    .font(.system(size: 30, weight: .bold))
                    .lineLimit(2, reservesSpace: true)

                if let description {
                    TVEpisodeDescriptionView(
                        title: selectedEpisode?.title ?? series.title,
                        text: description
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length / 3
                    }
                }
            }
            .padding(.horizontal, 72)
            .frame(minHeight: 250, alignment: .bottomLeading)
            .transaction { $0.disablesAnimations = true }
        }

        private func episodeSubtitle(_ episode: EntityThumbnail) -> String {
            var components: [String] = []
            if let season = seasons.first(where: { $0.id == selectedSeasonID }),
                let order = season.sortOrder
            {
                components.append("S\(order)")
            }
            if let order = episode.sortOrder { components.append("E\(order)") }
            components.append(episode.title)
            return components.joined(separator: " · ")
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Seasons Hero Copy · Episode · Accessibility Type") {
        PreviewShell {
            TVSeasonsHeroCopy(
                series: TVSeasonsPreviewData.series,
                selectedEpisode: TVSeasonsPreviewData.episodeThumbnail,
                selectedEpisodeDetail: TVSeasonsPreviewData.episode,
                seasons: [TVSeasonsPreviewData.seasonThumbnail],
                selectedSeasonID: TVSeasonsPreviewData.seasonID
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
