#if os(tvOS)
    import SwiftUI

    struct TVFullscreenPlayerSurface: View {
        let controller: VideoPlaybackController
        let title: String
        let trickplayPlaylistPath: String?
        let trickplayFrameLoader: (any TrickplayFrameLoading)?
        let onRequestDismiss: () -> Void

        init(
            controller: VideoPlaybackController,
            title: String,
            trickplayPlaylistPath: String? = nil,
            trickplayFrameLoader: (any TrickplayFrameLoading)? = nil,
            onRequestDismiss: @escaping () -> Void
        ) {
            self.controller = controller
            self.title = title
            self.trickplayPlaylistPath = trickplayPlaylistPath
            self.trickplayFrameLoader = trickplayFrameLoader
            self.onRequestDismiss = onRequestDismiss
        }

        var body: some View {
            if let request = controller.compatibilityPlaybackRequest {
                TVCompatibilityPlayerView(
                    controller: controller,
                    request: request,
                    title: title,
                    trickplayPlaylistPath: trickplayPlaylistPath,
                    trickplayFrameLoader: trickplayFrameLoader,
                    onRequestDismiss: onRequestDismiss
                )
            } else {
                TVFullscreenPlayerController(
                    controller: controller,
                    transportMenuSignature: transportMenuSignature,
                    assSubtitleContents: controller.activeAssSubtitleContents,
                    subtitleContent: controller.activeSubtitleContent,
                    subtitleAppearance: controller.subtitleAppearance,
                    onRequestDismiss: onRequestDismiss
                )
            }
        }

        private var transportMenuSignature: String {
            let audio = controller.audioChoices
                .map { "\($0.id):\($0.title)" }
                .joined(separator: "|")
            let subtitles = controller.subtitleChoices
                .map { "\($0.id):\($0.title)" }
                .joined(separator: "|")
            return [
                audio,
                subtitles,
                controller.selectedAudioChoiceID ?? "",
                controller.selectedSubtitleChoiceID,
                String(controller.playbackRate),
            ].joined(separator: "#")
        }
    }

    #if DEBUG
        #Preview("TV Fullscreen Player Surface") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )
            TVFullscreenPlayerSurface(
                controller: controller,
                title: "Signal in the Static",
                onRequestDismiss: {}
            )
        }
    #endif
#endif
