import SwiftUI

struct VideoFullscreenPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let controller: VideoPlaybackController?
    let title: String
    let isInteractive: Bool
    var requiresExplicitPlay = false
    var preparationPhase: VideoPlaybackPreparationPhase = .idle
    var playRequested = false
    var resumeSeconds: Double? = nil
    var onResume: () -> Void = {}
    var onRestart: () -> Void = {}
    var onDismiss: () -> Void = {}
    @State private var usesRotatedLandscapeFallback = false
    @State private var orientationController = VideoFullscreenOrientationController()

    func body(content: Content) -> some View {
        Group {
            #if os(macOS)
                content.sheet(isPresented: $isPresented, onDismiss: presentationDidDismiss) {
                    expandedPlayer
                }
            #else
                content.fullScreenCover(isPresented: $isPresented, onDismiss: presentationDidDismiss) {
                    expandedPlayer
                }
            #endif
        }
        .onChange(of: isPresented, initial: true) { _, isPresented in
            if isPresented {
                orientationController.prepareForPresentation()
            } else {
                orientationController.beginDismissal()
            }
        }
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
                usesRotatedFallback: $usesRotatedLandscapeFallback,
                controller: orientationController
            )
        )
        .background(Color.black.ignoresSafeArea())
    }

    private var expandedPlayerContent: some View {
        Group {
            if requiresExplicitPlay && !playRequested {
                VideoFullscreenPreparationView(
                    title: title,
                    phase: preparationPhase,
                    isReadyToPlay: controller != nil && isInteractive,
                    playRequested: false,
                    resumeSeconds: resumeSeconds,
                    onResume: onResume,
                    onRestart: onRestart,
                    onDismiss: requestDismissal
                )
            } else if let controller {
                PrismediaVideoPlayerView(
                    controller: controller,
                    title: title,
                    isInteractive: isInteractive,
                    isExpanded: true,
                    badges: controller.badges,
                    onFullscreen: requestDismissal,
                    onDismiss: requestDismissal
                )
            } else {
                VideoFullscreenPreparationView(
                    title: title,
                    phase: preparationPhase,
                    isReadyToPlay: false,
                    playRequested: playRequested,
                    resumeSeconds: resumeSeconds,
                    onResume: onResume,
                    onRestart: onRestart,
                    onDismiss: requestDismissal
                )
            }
        }
        .padding(PrismediaSpacing.small)
    }

    private func presentationDidDismiss() {
        orientationController.exitFullscreen()
        onDismiss()
    }

    private func requestDismissal() {
        orientationController.beginDismissal()
        isPresented = false
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
                    isInteractive: true,
                    requiresExplicitPlay: true,
                    preparationPhase: .ready,
                    playRequested: false,
                    resumeSeconds: 734,
                    onResume: {},
                    onRestart: {}
                )
            )
    }
#endif
