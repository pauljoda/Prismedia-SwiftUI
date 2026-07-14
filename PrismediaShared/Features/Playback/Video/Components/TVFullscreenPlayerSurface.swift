#if os(tvOS)
    import SwiftUI

    struct TVFullscreenPlayerSurface: View {
        let controller: VideoPlaybackController
        let onRequestDismiss: () -> Void

        var body: some View {
            TVFullscreenPlayerController(
                controller: controller,
                transportMenuSignature: transportMenuSignature,
                assSubtitleContents: controller.activeAssSubtitleContents,
                subtitleContent: controller.activeSubtitleContent,
                subtitleAppearance: controller.subtitleAppearance,
                onRequestDismiss: onRequestDismiss
            )
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
            TVFullscreenPlayerSurface(controller: controller, onRequestDismiss: {})
        }
    #endif
#endif
