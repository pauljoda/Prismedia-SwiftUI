import AVKit
import SwiftUI

#if os(tvOS)
struct PrismediaVideoPlayerView: View {
    let controller: VideoPlaybackController
    let title: String
    let isInteractive: Bool
    let isExpanded: Bool
    var badges: [VideoPlaybackBadge] = []
    let onFullscreen: () -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            VideoPlayer(player: controller.player)
            VideoSubtitlePlaybackOverlay(
                assContents: controller.activeAssSubtitleContents,
                content: controller.activeSubtitleContent,
                appearance: controller.subtitleAppearance,
                player: controller.player
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .accessibilityIdentifier("video-player.surface")
    }
}

#if DEBUG
    #Preview("TV Video Player") {
        let id = UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!
        let controller = VideoPlaybackController(videoID: id, service: VideoPlaybackPreviewService())
        PrismediaVideoPlayerView(
            controller: controller,
            title: "Signal in the Static",
            isInteractive: true,
            isExpanded: true,
            onFullscreen: {}
        )
        .background(Color.black)
    }
#endif
#endif
