import SwiftUI

#if os(tvOS)

    struct TVSeasonsPlaybackArea: View {
        @State private var preparation = VideoPlaybackPreparationCoordinator()
        let episode: EntityThumbnail?
        let episodeDetail: EntityDetail?
        let loader: any EntityDetailLoading
        let playbackService: (any VideoPlaybackServicing)?
        let autoPlayEpisodeID: UUID?
        let autoPlayRequestID: UUID?
        let onAdvance: (EntityLink) -> Void

        @ViewBuilder
        var body: some View {
            if let episodeDetail, let episode, let playbackService {
                VideoEntityPlaybackView(
                    detail: episodeDetail,
                    ownerLink: EntityLink(thumbnail: episode, intent: .playback),
                    detailLoader: loader,
                    playbackService: playbackService,
                    preparation: preparation,
                    tvLayout: .compact,
                    autoPlayOnTV: autoPlayEpisodeID == episodeDetail.id,
                    onAdvance: onAdvance
                )
                .id(episodeDetail.id.uuidString + "-" + (autoPlayRequestID?.uuidString ?? "manual"))
                .frame(minHeight: 80)
            } else if episode != nil {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .frame(width: 160, height: PrismediaLayout.minimumHitTarget)
                        .overlay { ProgressView().tint(PrismediaColor.onMedia) }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 72)
                .frame(minHeight: 80)
                .accessibilityLabel("Loading playback options")
            } else {
                Color.clear
                    .frame(height: 80)
                    .accessibilityHidden(true)
            }
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Seasons Playback Area · Ready") {
        PreviewShell {
            TVSeasonsPlaybackArea(
                episode: TVSeasonsPreviewData.episodeThumbnail,
                episodeDetail: TVSeasonsPreviewData.episode,
                loader: TVSeasonsPreviewData.loader,
                playbackService: VideoPlaybackPreviewService(),
                autoPlayEpisodeID: nil,
                autoPlayRequestID: nil,
                onAdvance: { _ in }
            )
        }
    }

    #Preview("TV Seasons Playback Area · Loading") {
        PreviewShell {
            TVSeasonsPlaybackArea(
                episode: TVSeasonsPreviewData.episodeThumbnail,
                episodeDetail: nil,
                loader: TVSeasonsPreviewData.loader,
                playbackService: nil,
                autoPlayEpisodeID: nil,
                autoPlayRequestID: nil,
                onAdvance: { _ in }
            )
        }
    }
#endif
