#if os(tvOS)
    import SwiftUI

    struct TVPlaybackScrubber: UIViewRepresentable {
        let controlsVisible: Bool
        let isGrabbed: Bool
        let onFocusChange: (Bool) -> Void
        let onRevealControls: () -> Void
        let onMoveToOptions: () -> Void
        let onPrimaryAction: () -> Void
        let onHorizontalPress: (VideoPlayerGestureSide) -> Void
        let onPanBegan: () -> Void
        let onPanChanged: (CGFloat) -> Void
        let onPanEnded: () -> Void

        func makeUIView(context: Context) -> TVPlaybackScrubberControl {
            TVPlaybackScrubberControl(frame: .zero)
        }

        func updateUIView(_ uiView: TVPlaybackScrubberControl, context: Context) {
            uiView.controlsVisible = controlsVisible
            uiView.isGrabbed = isGrabbed
            uiView.onFocusChange = onFocusChange
            uiView.onRevealControls = onRevealControls
            uiView.onMoveToOptions = onMoveToOptions
            uiView.onPrimaryAction = onPrimaryAction
            uiView.onHorizontalPress = onHorizontalPress
            uiView.onPanBegan = onPanBegan
            uiView.onPanChanged = onPanChanged
            uiView.onPanEnded = onPanEnded
        }
    }

    #if DEBUG
        #Preview("TV Playback Scrubber Focus Surface") {
            TVPlaybackScrubber(
                controlsVisible: true,
                isGrabbed: false,
                onFocusChange: { _ in },
                onRevealControls: {},
                onMoveToOptions: {},
                onPrimaryAction: {},
                onHorizontalPress: { _ in },
                onPanBegan: {},
                onPanChanged: { _ in },
                onPanEnded: {}
            )
            .frame(height: 132)
            .padding(64)
            .background(Color.black)
        }
    #endif
#endif
