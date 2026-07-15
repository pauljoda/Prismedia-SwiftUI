import SwiftUI

#if os(tvOS)
    struct TVEpisodeThumbnailBackdrop: View {
        let episode: EntityThumbnail?
        let seriesHeroPath: String?

        var body: some View {
            RemotePosterImage(
                path: episode?.bestCoverPath ?? seriesHeroPath,
                fallbackSeed: episode?.title ?? "Series",
                systemImage: "tv",
                retainsCurrentImageWhileLoading: true,
                maxPixelSize: 2_048
            )
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Episode Thumbnail Backdrop") {
        PreviewShell(signedIn: true) {
            TVEpisodeThumbnailBackdrop(
                episode: TVSeasonsPreviewData.episodeThumbnail,
                seriesHeroPath: "/preview/hero.jpg"
            )
        }
        .frame(width: 1_920, height: 1_080)
    }
#endif
