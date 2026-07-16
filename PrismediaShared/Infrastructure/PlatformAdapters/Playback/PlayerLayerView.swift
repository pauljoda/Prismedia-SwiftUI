#if !os(tvOS)
    import AVFoundation
    import SwiftUI

    #if canImport(UIKit)
        import UIKit

        final class PlayerLayerView: UIView {
            override class var layerClass: AnyClass { AVPlayerLayer.self }
            var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
            weak var playbackController: VideoPlaybackController?
            var onReadyForDisplayChange: ((Bool) -> Void)? {
                didSet { observeReadyForDisplay() }
            }
            private var readyForDisplayObservation: NSKeyValueObservation?

            private func observeReadyForDisplay() {
                readyForDisplayObservation?.invalidate()
                guard onReadyForDisplayChange != nil else { return }
                readyForDisplayObservation = playerLayer.observe(
                    \.isReadyForDisplay,
                    options: [.initial, .new]
                ) { [weak self] layer, _ in
                    let isReadyForDisplay = layer.isReadyForDisplay
                    Task { @MainActor [weak self] in
                        self?.onReadyForDisplayChange?(isReadyForDisplay)
                    }
                }
            }
        }
    #elseif canImport(AppKit)
        import AppKit

        final class PlayerLayerView: NSView {
            let playerLayer = AVPlayerLayer()
            weak var playbackController: VideoPlaybackController?
            var onReadyForDisplayChange: ((Bool) -> Void)? {
                didSet { observeReadyForDisplay() }
            }
            private var readyForDisplayObservation: NSKeyValueObservation?
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

            private func observeReadyForDisplay() {
                readyForDisplayObservation?.invalidate()
                guard onReadyForDisplayChange != nil else { return }
                readyForDisplayObservation = playerLayer.observe(
                    \.isReadyForDisplay,
                    options: [.initial, .new]
                ) { [weak self] layer, _ in
                    let isReadyForDisplay = layer.isReadyForDisplay
                    Task { @MainActor [weak self] in
                        self?.onReadyForDisplayChange?(isReadyForDisplay)
                    }
                }
            }
        }
    #endif

    #if DEBUG
        #Preview("Player Layer View") {
            PlayerLayerView()
        }
    #endif
#endif
