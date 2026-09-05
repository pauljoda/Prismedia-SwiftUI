import SwiftUI

#if os(tvOS)

    struct TVSeasonsHeroCopy<Playback: View>: View {
        let series: EntityDetail
        let selectedEpisode: EntityThumbnail?
        let selectedEpisodeDetail: EntityDetail?
        let seasons: [EntityThumbnail]
        let selectedSeasonID: UUID?
        @ViewBuilder let playback: () -> Playback

        var body: some View {
            let seriesPresentation = EntityDetailPresentation(detail: series)
            let description = TVEpisodeDescriptionPresentation.text(
                episode: selectedEpisode,
                episodeDetail: selectedEpisodeDetail,
                seriesDescription: seriesPresentation.description
            )

            HStack(alignment: .top, spacing: PrismediaSpacing.screen) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    Text(series.title)
                        .font(PrismediaTypography.sectionTitle)
                        .foregroundStyle(PrismediaColor.onMedia)
                        .lineLimit(1, reservesSpace: true)

                    Text(selectedEpisode.map(episodeSubtitle) ?? " ")
                        .font(PrismediaTypography.body.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia)
                        .lineLimit(2)

                    let badges = EntityDetailPresentation(
                        detail: selectedEpisodeDetail ?? series,
                        mediaThumbnail: selectedEpisode
                    ).mediaBadges
                    if !badges.isEmpty {
                        EntityDetailMediaChipsView(badges: badges)
                    }

                    playback()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let description {
                    TVEpisodeDescriptionView(
                        title: selectedEpisode?.displayTitle ?? series.title,
                        text: description
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in length / 3 }
                    .prismediaFocusSection()
                }
            }
            .padding(.horizontal, PrismediaLayout.televisionContentInset)
            .frame(minHeight: PrismediaLayout.televisionDetailSummaryMinimumHeight, alignment: .bottomLeading)
            .transaction { $0.disablesAnimations = true }
        }

        private func episodeSubtitle(_ episode: EntityThumbnail) -> String {
            var components: [String] = []
            if let season = seasons.first(where: { $0.id == selectedSeasonID }),
                let order = season.sortOrder
            {
                components.append("S\(order)")
            }
            if let position = episode.sharedEpisodePositionLabel {
                components.append(position)
            } else if let order = episode.sortOrder {
                components.append("E\(order)")
            }
            components.append(episode.displayTitle)
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
            ) {
                TVPlaybackLaunchButton(title: "Play", systemImage: "play.fill", isPrimary: true) {}
            }
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
