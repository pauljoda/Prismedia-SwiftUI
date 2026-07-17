import AVFoundation

@MainActor
struct VideoPictureInPictureHandoff {
    let shouldRequest: (VideoPlaybackController) -> Bool
    let isActiveOrStarting: (VideoPlaybackController) -> Bool
    let request: (VideoPlaybackController) -> Void

    static let live = Self(
        shouldRequest: { controller in
            guard controller.renderer == .native else { return false }
            return VideoPlaybackVisibilityPolicy.shouldEnterPictureInPicture(
                isPlaying: controller.isPlaying,
                isWaiting: controller.isWaiting,
                playerRate: controller.player.rate
            )
        },
        isActiveOrStarting: { $0.pictureInPicture.isActiveOrStarting },
        request: { $0.startPictureInPicture() }
    )
}
