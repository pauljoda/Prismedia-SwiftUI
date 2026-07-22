import SwiftUI

extension EntityDetailView {
    @ViewBuilder
    func inlineVideoPlaybackView(
        _ detail: EntityDetail,
        ownerLink: EntityLink?
    ) -> some View {
        if let ownerLink,
            VideoPlaybackLaunchPolicy.presentationMode(for: ownerLink) == .inline,
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
                presentationMode: VideoPlaybackLaunchPolicy.presentationMode(for: ownerLink),
                presentsFullscreenOnTV: VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                    for: ownerLink.intent
                ),
                onFullscreenDismiss: {
                    guard VideoPlaybackLaunchPolicy.presentationMode(for: ownerLink) == .fullscreenOnly else {
                        return
                    }
                    suppressesRoutePlayback = true
                    thumbnailPlaybackLink = nil
                },
                onPlaybackProgressCommitted: {
                    Task { await refreshPlaybackState() }
                },
                onAdvance: { destination in
                    guard ownerLink.kind != .videoSeason else { return }
                    advancedEntityLink = destination
                }
            )
            .id(ownerLink)
        }
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
                onFullscreenDismiss: {
                    suppressesRoutePlayback = true
                    thumbnailPlaybackLink = nil
                },
                onPlaybackProgressCommitted: {
                    Task { await refreshPlaybackState() }
                },
                onAdvance: { _ in }
            )
            .id(ownerLink)
        }
    }
}
