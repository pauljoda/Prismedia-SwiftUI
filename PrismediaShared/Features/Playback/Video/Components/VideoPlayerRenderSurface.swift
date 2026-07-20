#if !os(tvOS)
    import SwiftUI

    struct VideoPlayerRenderSurface: View {
        let controller: VideoPlaybackController

        var body: some View {
            if let request = controller.compatibilityPlaybackRequest {
                #if canImport(MobileVLCKit) || canImport(VLCKit)
                    CompatibilityVideoSurface(
                        controller: controller,
                        request: request
                    )
                #else
                    Color.black
                #endif
            } else {
                NativeVideoSurface(
                    controller: controller,
                    scalingMode: controller.videoScalingMode
                )
            }
        }
    }

    #if DEBUG
        #Preview("Video Player Render Surface") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                service: VideoPlaybackPreviewService()
            )

            VideoPlayerRenderSurface(controller: controller)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .background(.black)
        }
    #endif
#endif
