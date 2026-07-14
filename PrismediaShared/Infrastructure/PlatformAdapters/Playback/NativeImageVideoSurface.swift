import AVFoundation
import SwiftUI

#if canImport(UIKit)
    import UIKit

    struct NativeImageVideoSurface: UIViewRepresentable {
        let player: AVPlayer
        let videoGravity: AVLayerVideoGravity

        func makeUIView(context: Context) -> EntityImagePlayerLayerView {
            let view = EntityImagePlayerLayerView()
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(_ view: EntityImagePlayerLayerView, context: Context) {
            view.playerLayer.player = player
            view.playerLayer.videoGravity = videoGravity
        }

        static func dismantleUIView(_ view: EntityImagePlayerLayerView, coordinator: Void) {
            view.playerLayer.player = nil
        }
    }
#elseif canImport(AppKit)
    import AppKit

    struct NativeImageVideoSurface: NSViewRepresentable {
        let player: AVPlayer
        let videoGravity: AVLayerVideoGravity

        func makeNSView(context: Context) -> EntityImagePlayerLayerView {
            EntityImagePlayerLayerView()
        }

        func updateNSView(_ view: EntityImagePlayerLayerView, context: Context) {
            view.playerLayer.player = player
            view.playerLayer.videoGravity = videoGravity
        }

        static func dismantleNSView(_ view: EntityImagePlayerLayerView, coordinator: Void) {
            view.playerLayer.player = nil
        }
    }
#endif

#if DEBUG
    #Preview("Native Image Video Surface") {
        NativeImageVideoSurface(
            player: AVPlayer(),
            videoGravity: .resizeAspect
        )
        .frame(width: 320, height: 180)
        .background(PrismediaColor.background)
    }
#endif
