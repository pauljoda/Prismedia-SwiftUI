#if os(tvOS)
    import SwiftUI

    struct TVPlayerRenderSurface: View {
        let controller: VideoPlaybackController
        let compatibilityRequest: VideoCompatibilityPlaybackRequest?

        var body: some View {
            if let compatibilityRequest {
                TVVLCPlayerController(
                    request: compatibilityRequest,
                    controller: controller
                )
            } else {
                NativeVideoSurface(
                    controller: controller,
                    scalingMode: controller.videoScalingMode
                )
            }
        }
    }

    #if DEBUG
        #Preview("TV Player Render Surface") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )

            TVPlayerRenderSurface(
                controller: controller,
                compatibilityRequest: nil
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .background(.black)
        }
    #endif
#endif
