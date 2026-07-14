#if !os(tvOS)
    import AVFoundation
    import SwiftUI

    #if canImport(UIKit)
        import UIKit

        struct NativeVideoSurface: UIViewRepresentable {
            let controller: VideoPlaybackController
            let scalingMode: VideoScalingMode

            func makeUIView(context: Context) -> PlayerLayerView {
                let view = PlayerLayerView()
                view.backgroundColor = .black
                view.playerLayer.videoGravity = scalingMode == .fit ? .resizeAspect : .resizeAspectFill
                view.playerLayer.player = controller.player
                view.playbackController = controller
                controller.attachPictureInPicture(to: view.playerLayer)
                return view
            }

            func updateUIView(_ view: PlayerLayerView, context: Context) {
                view.playerLayer.player = controller.player
                view.playbackController = controller
                view.playerLayer.videoGravity = scalingMode == .fit ? .resizeAspect : .resizeAspectFill
                controller.attachPictureInPicture(to: view.playerLayer)
            }

            static func dismantleUIView(_ view: PlayerLayerView, coordinator: Void) {
                // Detach only the transient visual surface. The page-owned controller
                // keeps its AVPlayer alive and reattaches when the surface returns.
                view.playbackController?.detachPictureInPicture(from: view.playerLayer)
            }
        }

    #elseif canImport(AppKit)
        import AppKit

        struct NativeVideoSurface: NSViewRepresentable {
            let controller: VideoPlaybackController
            let scalingMode: VideoScalingMode

            func makeNSView(context: Context) -> PlayerLayerView {
                PlayerLayerView()
            }

            func updateNSView(_ view: PlayerLayerView, context: Context) {
                view.playerLayer.player = controller.player
                view.playerLayer.videoGravity = scalingMode == .fit ? .resizeAspect : .resizeAspectFill
            }

            static func dismantleNSView(_ view: PlayerLayerView, coordinator: Void) {
                view.playerLayer.player = nil
            }
        }
    #endif

    #if DEBUG
        #Preview("Native Video Surface") {
            let controller = VideoPlaybackController(
                videoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                service: VideoPlaybackPreviewService()
            )

            NativeVideoSurface(controller: controller, scalingMode: .fit)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .background(.black)
        }
    #endif
#endif
