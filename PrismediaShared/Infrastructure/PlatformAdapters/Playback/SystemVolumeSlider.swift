#if os(iOS)
    import AVKit
    import MediaPlayer
    import SwiftUI

    /// SwiftUI-facing wrappers for the two system audio controls that do not yet
    /// have native SwiftUI equivalents.
    struct SystemVolumeSlider: UIViewRepresentable {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: .zero)
            applyArtworkAccent(to: volumeView)
            return volumeView
        }

        func updateUIView(_ uiView: MPVolumeView, context: Context) {
            applyArtworkAccent(to: uiView)
        }

        private func applyArtworkAccent(to uiView: MPVolumeView) {
            uiView.tintColor = UIColor(artworkPrimaryAccent)
            for slider in uiView.subviews.compactMap({ $0 as? UISlider }) {
                slider.minimumTrackTintColor = UIColor(artworkPrimaryAccent)
            }
        }
    }

    #if DEBUG
        #Preview("System Volume Slider") {
            SystemVolumeSlider()
                .frame(height: PrismediaLayout.minimumHitTarget)
                .padding()
                .background(.black)
        }
    #endif
#endif
