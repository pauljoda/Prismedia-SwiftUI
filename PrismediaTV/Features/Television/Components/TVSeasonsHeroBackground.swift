import SwiftUI

#if os(tvOS)

    struct TVSeasonsHeroBackground: View {
        let series: EntityDetail
        let selectedEpisode: EntityThumbnail?
        let paletteArtworkPath: String?
        @Binding var palette: ArtworkPalette?

        var body: some View {
            ArtworkPaletteSurface(
                artworkPath: paletteArtworkPath,
                paletteArtworkPath: paletteArtworkPath,
                fallbackSeed: series.title,
                systemImage: "tv",
                showsArtworkInBackdrop: false,
                palette: $palette
            ) {
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
        }

        private var seriesHeroPath: String? {
            let presentation = EntityDetailPresentation(detail: series)
            return presentation.heroPath ?? presentation.posterPath
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Seasons Hero Background · Episode") {
        @Previewable @State var palette: ArtworkPalette?
        PreviewShell {
            TVSeasonsHeroBackground(
                series: TVSeasonsPreviewData.series,
                selectedEpisode: TVSeasonsPreviewData.episodeThumbnail,
                paletteArtworkPath: "/preview/poster.jpg",
                palette: $palette
            )
            .ignoresSafeArea()
        }
    }
#endif
