import SwiftUI

#if os(tvOS)

    struct TVSeasonsPlaybackArea: View {
        @State private var preparation = VideoPlaybackPreparationCoordinator()
        let episode: EntityThumbnail?
        let episodeDetail: EntityDetail?
        let loader: any EntityDetailLoading
        let playbackService: (any VideoPlaybackServicing)?
        let fullscreenRequest: TVEpisodePlaybackRequest?
        let onFullscreenDismiss: (TVEpisodePlaybackRequest?, UUID) -> Void
        let onPlaybackProgressCommitted: (UUID) -> Void
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
                    presentsFullscreenOnTV: fullscreenRequest?.episodeID == episodeDetail.id,
                    onFullscreenDismiss: {
                        onFullscreenDismiss(fullscreenRequest, episodeDetail.id)
                    },
                    onPlaybackProgressCommitted: {
                        onPlaybackProgressCommitted(episodeDetail.id)
                    },
                    onAdvance: onAdvance
                )
                .id(episodeDetail.id.uuidString + "-" + (fullscreenRequest?.id.uuidString ?? "manual"))
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
                fullscreenRequest: nil,
                onFullscreenDismiss: { _, _ in },
                onPlaybackProgressCommitted: { _ in },
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
                fullscreenRequest: nil,
                onFullscreenDismiss: { _, _ in },
                onPlaybackProgressCommitted: { _ in },
                onAdvance: { _ in }
            )
        }
    }
#endif
