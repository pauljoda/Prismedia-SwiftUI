import Foundation

@MainActor
struct VideoSystemPlaybackIntegration {
    static let inactive = VideoSystemPlaybackIntegration(
        activate: { _, _ in },
        deactivate: { _ in }
    )

    private let activateController: (VideoPlaybackController, VideoNowPlayingMetadata) -> Void
    private let deactivateController: (VideoPlaybackController) -> Void

    init(
        activate: @escaping (VideoPlaybackController, VideoNowPlayingMetadata) -> Void,
        deactivate: @escaping (VideoPlaybackController) -> Void
    ) {
        activateController = activate
        deactivateController = deactivate
    }

    func activate(
        _ controller: VideoPlaybackController,
        metadata: VideoNowPlayingMetadata
    ) {
        activateController(controller, metadata)
    }

    func deactivate(_ controller: VideoPlaybackController) {
        deactivateController(controller)
    }
}
