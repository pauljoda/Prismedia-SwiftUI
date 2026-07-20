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
            view.onReadyForDisplayChange = { [weak controller] isReady in
                controller?.videoSurfaceReadinessChanged(isReady)
            }
            controller.videoSurfaceDidAttach(isReadyForDisplay: view.playerLayer.isReadyForDisplay)
            #if os(iOS)
                controller.attachPictureInPicture(to: view.playerLayer)
            #endif
            return view
        }

        func updateUIView(_ view: PlayerLayerView, context: Context) {
            view.playerLayer.player = controller.player
            view.playbackController = controller
            view.onReadyForDisplayChange = { [weak controller] isReady in
                controller?.videoSurfaceReadinessChanged(isReady)
            }
            controller.videoSurfaceDidAttach(isReadyForDisplay: view.playerLayer.isReadyForDisplay)
            view.playerLayer.videoGravity = scalingMode == .fit ? .resizeAspect : .resizeAspectFill
            #if os(iOS)
                controller.attachPictureInPicture(to: view.playerLayer)
            #endif
        }

        static func dismantleUIView(_ view: PlayerLayerView, coordinator: Void) {
            // Detach only the transient visual surface. The page-owned controller
            // keeps its AVPlayer alive and reattaches when the surface returns.
            view.playbackController?.videoSurfaceDidDetach()
            #if os(iOS)
                view.playbackController?.detachPictureInPicture(from: view.playerLayer)
            #endif
            view.onReadyForDisplayChange = nil
            view.playbackController = nil
        }
    }

#elseif canImport(AppKit)
    import AppKit

    struct NativeVideoSurface: NSViewRepresentable {
        let controller: VideoPlaybackController
        let scalingMode: VideoScalingMode

        func makeNSView(context: Context) -> PlayerLayerView {
            let view = PlayerLayerView()
            configure(view)
            return view
        }

        func updateNSView(_ view: PlayerLayerView, context: Context) {
            configure(view)
        }

        private func configure(_ view: PlayerLayerView) {
            view.playerLayer.player = controller.player
            view.playerLayer.videoGravity = scalingMode == .fit ? .resizeAspect : .resizeAspectFill
            view.playbackController = controller
            view.onReadyForDisplayChange = { [weak controller] isReady in
                controller?.videoSurfaceReadinessChanged(isReady)
            }
            controller.videoSurfaceDidAttach(isReadyForDisplay: view.playerLayer.isReadyForDisplay)
        }

        static func dismantleNSView(_ view: PlayerLayerView, coordinator: Void) {
            view.playbackController?.videoSurfaceDidDetach()
            view.onReadyForDisplayChange = nil
            view.playbackController = nil
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
