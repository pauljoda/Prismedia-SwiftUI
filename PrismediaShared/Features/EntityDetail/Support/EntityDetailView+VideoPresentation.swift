import SwiftUI

extension EntityDetailView {
    @ViewBuilder
    func televisionVideoPlaybackActions(
        _ detail: EntityDetail,
        ownerLink: EntityLink?
    ) -> some View {
        #if os(tvOS)
            if let ownerLink,
                PlayableVideoResolver.videoID(
                    in: detail,
                    sourceThumbnail: ownerLink.sourceThumbnail
                ) != nil,
                let playbackService = dependencies.videoPlaybackService
            {
                VideoEntityPlaybackView(
                    detail: detail,
                    ownerLink: ownerLink,
                    detailLoader: dependencies.detailLoader,
                    playbackService: playbackService,
                    trickplayFrameLoader: dependencies.trickplayFrameLoader,
                    preparation: videoPlaybackPreparation,
                    presentationMode: .inline,
                    onPlaybackPositionChanged: receiveVideoPlaybackProgress,
                    onPlaybackProgressCommitted: { _ in
                        dependencies.onEntityMutated()
                        Task { await refreshContainerProgressIfNeeded(detail) }
                    },
                    onAdvance: { destination in
                        guard ownerLink.kind != .videoSeason else { return }
                        advancedEntityLink = destination
                    }
                )
                .id(ownerLink)
            }
        #else
            EmptyView()
        #endif
    }

    @ViewBuilder
    func fullscreenVideoPlaybackView(
        _ detail: EntityDetail,
        ownerLink: EntityLink?
    ) -> some View {
        if let ownerLink,
            VideoPlaybackLaunchPolicy.presentationMode(for: ownerLink) == .fullscreenOnly,
            PlayableVideoResolver.videoID(
                in: detail,
                sourceThumbnail: ownerLink.sourceThumbnail
            ) != nil,
            let playbackService = dependencies.videoPlaybackService
        {
            VideoEntityPlaybackView(
                detail: detail,
                ownerLink: ownerLink,
                detailLoader: dependencies.detailLoader,
                playbackService: playbackService,
                trickplayFrameLoader: dependencies.trickplayFrameLoader,
                preparation: videoPlaybackPreparation,
                presentationMode: .fullscreenOnly,
                presentsFullscreenOnTV: VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                    for: ownerLink.intent
                ),
                startsFullscreenPlaybackImmediately: thumbnailPlaybackLink != nil
                    || ownerLink.playbackRequestID != nil,
                fullscreenPlaybackStartOverrideSeconds: videoPlaybackStartOverrideSeconds
                    ?? ownerLink.playbackStartSeconds,
                onFullscreenDismiss: {
                    suppressesRoutePlayback = true
                    thumbnailPlaybackLink = nil
                    videoPlaybackStartOverrideSeconds = nil
                },
                onPlaybackPositionChanged: { progress in
                    receiveVideoPlaybackProgress(progress)
                },
                onPlaybackProgressCommitted: { _ in
                    dependencies.onEntityMutated()
                    Task { await refreshContainerProgressIfNeeded(detail) }
                },
                onAdvance: { _ in }
            )
            .id(ownerLink)
        }
    }

    func receiveVideoPlaybackProgress(
        _ progress: VideoPlaybackProgressSnapshot
    ) {
        if progress.durationSeconds > 0,
            progress.positionSeconds >= progress.durationSeconds - 1
        {
            liveVideoResumeSeconds = 0
        } else {
            liveVideoResumeSeconds = progress.positionSeconds
        }
    }

    func refreshContainerProgressIfNeeded(_ detail: EntityDetail) async {
        guard detail.kind == .videoSeries || detail.kind == .videoSeason else { return }
        await loadVideoProgress(for: detail)
    }
}
