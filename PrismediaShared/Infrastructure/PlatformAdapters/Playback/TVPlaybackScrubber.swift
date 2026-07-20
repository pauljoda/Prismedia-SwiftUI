#if os(tvOS)
    import SwiftUI

    struct TVPlaybackScrubber<Content: View>: UIViewRepresentable {
        let controlsVisible: Bool
        let isFocusEnabled: Bool
        let isGrabbed: Bool
        let isScrollingEnabled: Bool
        let onFocusChange: (Bool) -> Void
        let onRevealControls: () -> Void
        let onMoveToOptions: () -> Void
        let onPrimaryAction: () -> Void
        let onHorizontalPress: (VideoPlayerGestureSide) -> Void
        let onPanBegan: () -> Void
        let onPanChanged: (CGFloat) -> Void
        let onPanEnded: () -> Void
        let content: Content

        init(
            controlsVisible: Bool,
            isFocusEnabled: Bool,
            isGrabbed: Bool,
            isScrollingEnabled: Bool,
            onFocusChange: @escaping (Bool) -> Void,
            onRevealControls: @escaping () -> Void,
            onMoveToOptions: @escaping () -> Void,
            onPrimaryAction: @escaping () -> Void,
            onHorizontalPress: @escaping (VideoPlayerGestureSide) -> Void,
            onPanBegan: @escaping () -> Void,
            onPanChanged: @escaping (CGFloat) -> Void,
            onPanEnded: @escaping () -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.controlsVisible = controlsVisible
            self.isFocusEnabled = isFocusEnabled
            self.isGrabbed = isGrabbed
            self.isScrollingEnabled = isScrollingEnabled
            self.onFocusChange = onFocusChange
            self.onRevealControls = onRevealControls
            self.onMoveToOptions = onMoveToOptions
            self.onPrimaryAction = onPrimaryAction
            self.onHorizontalPress = onHorizontalPress
            self.onPanBegan = onPanBegan
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
            self.content = content()
        }

        func makeUIView(context: Context) -> TVPlaybackScrubberControl {
            TVPlaybackScrubberControl(content: AnyView(content))
        }

        func updateUIView(_ uiView: TVPlaybackScrubberControl, context: Context) {
            uiView.setContent(AnyView(content))
            uiView.controlsVisible = controlsVisible
            uiView.isEnabled = isFocusEnabled
            uiView.isGrabbed = isGrabbed
            uiView.isScrollingEnabled = isScrollingEnabled
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
                isFocusEnabled: true,
                isGrabbed: false,
                isScrollingEnabled: true,
                onFocusChange: { _ in },
                onRevealControls: {},
                onMoveToOptions: {},
                onPrimaryAction: {},
                onHorizontalPress: { _ in },
                onPanBegan: {},
                onPanChanged: { _ in },
                onPanEnded: {}
            ) {
                Color.clear
            }
            .frame(height: 132)
            .padding(64)
            .background(Color.black)
        }
    #endif
#endif
