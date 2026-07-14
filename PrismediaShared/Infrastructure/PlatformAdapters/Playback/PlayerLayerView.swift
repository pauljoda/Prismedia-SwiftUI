#if !os(tvOS)
    import AVFoundation
    import SwiftUI

    #if canImport(UIKit)
        import UIKit

        final class PlayerLayerView: UIView {
            override class var layerClass: AnyClass { AVPlayerLayer.self }
            var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
            weak var playbackController: VideoPlaybackController?
        }
    #elseif canImport(AppKit)
        import AppKit

        final class PlayerLayerView: NSView {
            let playerLayer = AVPlayerLayer()
            override init(frame frameRect: NSRect) {
                super.init(frame: frameRect)
                wantsLayer = true
                layer = playerLayer
                playerLayer.videoGravity = .resizeAspect
            }
            required init?(coder: NSCoder) { nil }
            override func layout() {
                super.layout()
                playerLayer.frame = bounds
            }
        }
    #endif

    #if DEBUG
        #Preview("Player Layer View") {
            PlayerLayerView()
        }
    #endif
#endif
