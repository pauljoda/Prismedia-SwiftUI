import AVFoundation
import SwiftUI

#if canImport(UIKit)
    import UIKit

    final class EntityImagePlayerLayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
#elseif canImport(AppKit)
    import AppKit

    final class EntityImagePlayerLayerView: NSView {
        let playerLayer = AVPlayerLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = playerLayer
        }

        required init?(coder: NSCoder) { nil }

        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }
    }
#endif

#if DEBUG
    #Preview("Image Player Layer") {
        EntityImagePlayerLayerView()
    }
#endif
