import SwiftUI

#if os(tvOS)

    struct TVSeasonsHeroBackground: View {
        let series: EntityDetail
        let selectedEpisode: EntityThumbnail?

        var body: some View {
            TVEpisodeThumbnailBackdrop(
                episode: selectedEpisode,
                seriesHeroPath: seriesHeroPath
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [.black.opacity(0.12), .black.opacity(0.48), .black.opacity(0.96)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [.black.opacity(0.82), .black.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .allowsHitTesting(false)
            }
        }

        private var seriesHeroPath: String? {
            let presentation = EntityDetailPresentation(detail: series)
            return presentation.heroPath ?? presentation.posterPath
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Seasons Hero Background · Episode") {
        PreviewShell {
            TVSeasonsHeroBackground(
                series: TVSeasonsPreviewData.series,
                selectedEpisode: TVSeasonsPreviewData.episodeThumbnail
            )
            .ignoresSafeArea()
        }
    }
#endif
