import SwiftUI

struct VideoFullscreenPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let controller: VideoPlaybackController
    let title: String
    let isInteractive: Bool
    @State private var usesRotatedLandscapeFallback = false

    func body(content: Content) -> some View {
        #if os(macOS)
            content.sheet(isPresented: $isPresented) { expandedPlayer }
        #else
            content.fullScreenCover(isPresented: $isPresented) { expandedPlayer }
        #endif
    }

    private var expandedPlayer: some View {
        Group {
            #if os(iOS)
                expandedPlayerLayout
                    .statusBarHidden(true)
                    .persistentSystemOverlays(.hidden)
            #else
                expandedPlayerLayout
            #endif
        }
        .suppressesMusicMiniPlayer()
    }

    private var expandedPlayerLayout: some View {
        GeometryReader { geometry in
            let rotatesContent = VideoFullscreenLayout.shouldRotateFallback(
                enabled: usesRotatedLandscapeFallback,
                width: geometry.size.width,
                height: geometry.size.height
            )
            expandedPlayerContent
                .frame(
                    width: rotatesContent ? geometry.size.height : geometry.size.width,
                    height: rotatesContent ? geometry.size.width : geometry.size.height
                )
                .rotationEffect(.degrees(rotatesContent ? 90 : 0))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .background(
            VideoFullscreenOrientationRequest(
                usesRotatedFallback: $usesRotatedLandscapeFallback
            )
        )
        .background(Color.black.ignoresSafeArea())
    }

    private var expandedPlayerContent: some View {
        PrismediaVideoPlayerView(
            controller: controller,
            title: title,
            isInteractive: isInteractive,
            isExpanded: true,
            badges: controller.badges,
            onFullscreen: { isPresented = false },
            onDismiss: { isPresented = false }
        )
        .padding(PrismediaSpacing.small)
    }
}

#if DEBUG
    #Preview("Fullscreen Presentation Modifier") {
        @Previewable @State var isPresented = false
        let controller = VideoPlaybackController(
            videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
            service: VideoPlaybackPreviewService()
        )
        Color.black
            .overlay { Text("Inline Player").foregroundStyle(PrismediaColor.onMedia) }
            .modifier(
                VideoFullscreenPresentationModifier(
                    isPresented: $isPresented,
                    controller: controller,
                    title: "Signal in the Static",
                    isInteractive: true
                )
            )
    }
#endif
