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
    var trickplayPlaylistPath: String? = nil
    var trickplayFrameLoader: (any TrickplayFrameLoading)? = nil
    var onResume: () -> Void = {}
    var onRestart: () -> Void = {}
    var onDismiss: () -> Void = {}
    /// Live source for the fullscreen content. When set, the hosted player reads
    /// phase/controller/title from this observable object directly instead of the
    /// value snapshots above — the presenting hierarchy stops rendering while it
    /// is covered by the player, so snapshots piped through it never update.
    var preparationCoordinator: VideoPlaybackPreparationCoordinator? = nil
    @State private var usesRotatedLandscapeFallback = false
    @State private var orientationController = VideoFullscreenOrientationController()
    #if os(macOS)
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @State private var macFullscreenWindowController = MacVideoFullscreenWindowController()
    #elseif os(iOS)
        @State private var fullscreenPresentationController =
            VideoFullscreenPresentationController()
    #endif

    func body(content: Content) -> some View {
        Group {
            #if os(macOS)
                content
                    .background {
                        MacVideoFullscreenPresentationBridge(
                            isPresented: isPresented,
                            fullscreenContent: expandedPlayer
                                .environment(\.artworkPrimaryAccent, artworkPrimaryAccent)
                                .preferredColorScheme(.dark),
                            windowController: macFullscreenWindowController,
                            onDismiss: macPresentationDidDismiss
                        )
                    }
                    .onDisappear {
                        macFullscreenWindowController.closeImmediately()
                    }
            #elseif os(iOS)
                // Deliberately no `.onDisappear` cleanup here: presenting the
                // player removes the presenting hierarchy on device, so
                // onDisappear fires while the player is showing and closing the
                // presentation from it would dismiss the player it just opened.
                // The hosted root below is self-sufficient for the same reason:
                // the covered hierarchy stops rendering, so the player must
                // observe playback state itself and dismiss through UIKit
                // directly rather than round-tripping through this view.
                content
                    .background {
                        VideoFullscreenPresentationBridge(
                            isPresented: isPresented,
                            fullscreenContent: hostedRoot,
                            contentID: nil,
                            presentationController: fullscreenPresentationController,
                            onDismiss: iOSPresentationDidDismiss
                        )
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
        Group {
            #if os(iOS)
                expandedPlayerGeometry
                    .ignoresSafeArea()
            #else
                expandedPlayerGeometry
            #endif
        }
        .background(
            VideoFullscreenOrientationRequest(
                usesRotatedFallback: $usesRotatedLandscapeFallback,
                controller: orientationController
            )
        )
        .background(Color.black.ignoresSafeArea())
    }

    private var expandedPlayerGeometry: some View {
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
                    trickplayPlaylistPath: trickplayPlaylistPath,
                    trickplayFrameLoader: trickplayFrameLoader,
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
    }

    private func presentationDidDismiss() {
        orientationController.exitFullscreen()
        onDismiss()
    }

    #if os(macOS)
        private func macPresentationDidDismiss() {
            if isPresented {
                isPresented = false
            }
            presentationDidDismiss()
        }
    #elseif os(iOS)
        private func iOSPresentationDidDismiss() {
            if isPresented {
                isPresented = false
            }
            presentationDidDismiss()
        }

        private var hostedRoot: some View {
            VideoFullscreenHostedRoot(
                preparation: preparationCoordinator,
                fallbackController: controller,
                fallbackTitle: title,
                requiresExplicitPlay: requiresExplicitPlay,
                fallbackPhase: preparationPhase,
                fallbackPlayRequested: playRequested,
                fallbackResumeSeconds: resumeSeconds,
                trickplayPlaylistPath: trickplayPlaylistPath,
                trickplayFrameLoader: trickplayFrameLoader,
                orientationController: orientationController,
                onResume: onResume,
                onRestart: onRestart,
                onRequestDismiss: { [orientationController, fullscreenPresentationController] in
                    #if DEBUG
                        print("Video fullscreen received an explicit dismiss action.")
                    #endif
                    orientationController.beginDismissal()
                    fullscreenPresentationController.requestDismissal()
                }
            )
        }
    #endif

    private func requestDismissal() {
        #if DEBUG
            print("Video fullscreen received an explicit dismiss action.")
        #endif
        orientationController.beginDismissal()
        isPresented = false
    }
}

#if os(iOS)
    /// Root view of the UIKit-presented fullscreen player. Self-sufficient by
    /// design: while the player covers the launching page, that page's hierarchy
    /// stops rendering, so nothing may depend on values piped through it. This
    /// view reads the preparation coordinator and playback controller directly —
    /// both are `@Observable`, and the hosting controller has its own render
    /// loop — and dismisses through UIKit, never through the covered page.
    private struct VideoFullscreenHostedRoot: View {
        let preparation: VideoPlaybackPreparationCoordinator?
        let fallbackController: VideoPlaybackController?
        let fallbackTitle: String
        let requiresExplicitPlay: Bool
        let fallbackPhase: VideoPlaybackPreparationPhase
        let fallbackPlayRequested: Bool
        let fallbackResumeSeconds: Double?
        let trickplayPlaylistPath: String?
        let trickplayFrameLoader: (any TrickplayFrameLoading)?
        let orientationController: VideoFullscreenOrientationController
        let onResume: () -> Void
        let onRestart: () -> Void
        let onRequestDismiss: () -> Void
        @State private var usesRotatedLandscapeFallback = false

        private var liveController: VideoPlaybackController? {
            preparation?.controller ?? fallbackController
        }

        private var livePhase: VideoPlaybackPreparationPhase {
            preparation?.phase ?? fallbackPhase
        }

        private var livePlayRequested: Bool {
            preparation?.playRequested ?? fallbackPlayRequested
        }

        private var liveResumeSeconds: Double? {
            preparation?.requestedResumeSeconds ?? fallbackResumeSeconds
        }

        private var liveTitle: String {
            preparation?.videoDetail?.title ?? fallbackTitle
        }

        private var liveIsInteractive: Bool {
            guard let controller = liveController else { return false }
            return VideoPlaybackReadiness.isInteractive(
                playerReady: controller.isReadyToPlay,
                optionsReady: controller.arePlaybackOptionsReady
            )
        }

        /// The static path is captured before the video detail resolves and is
        /// usually nil for detail-page launches; the resolved detail is the live
        /// source for the scrubber's trickplay frames.
        private var liveTrickplayPlaylistPath: String? {
            if let trickplayPlaylistPath { return trickplayPlaylistPath }
            return preparation?.videoDetail?.capabilities.compactMap { capability -> String? in
                guard case .files(let files) = capability else { return nil }
                return files.items.first(where: { $0.role == "trickplay" })?.path
            }.first
        }

        var body: some View {
            Group {
                if liveController?.videoScalingMode == .fill {
                    playerGeometry
                        .ignoresSafeArea()
                } else {
                    // Fit keeps the video (and its chrome) inside the safe area
                    // so letterboxed content never sits under hardware cutouts.
                    playerGeometry
                }
            }
            .background(
                VideoFullscreenOrientationRequest(
                    usesRotatedFallback: $usesRotatedLandscapeFallback,
                    controller: orientationController
                )
            )
            .background(Color.black.ignoresSafeArea())
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .suppressesMusicMiniPlayer()
        }

        private var playerGeometry: some View {
            GeometryReader { geometry in
                let rotatesContent = VideoFullscreenLayout.shouldRotateFallback(
                    enabled: usesRotatedLandscapeFallback,
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                playerContent
                    .frame(
                        width: rotatesContent ? geometry.size.height : geometry.size.width,
                        height: rotatesContent ? geometry.size.width : geometry.size.height
                    )
                    .rotationEffect(.degrees(rotatesContent ? 90 : 0))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }

        private var playerContent: some View {
            Group {
                if requiresExplicitPlay && !livePlayRequested {
                    VideoFullscreenPreparationView(
                        title: liveTitle,
                        phase: livePhase,
                        isReadyToPlay: liveController != nil && liveIsInteractive,
                        playRequested: false,
                        resumeSeconds: liveResumeSeconds,
                        onResume: onResume,
                        onRestart: onRestart,
                        onDismiss: onRequestDismiss
                    )
                } else if let controller = liveController {
                    PrismediaVideoPlayerView(
                        controller: controller,
                        title: liveTitle,
                        isInteractive: liveIsInteractive,
                        isExpanded: true,
                        badges: controller.badges,
                        trickplayPlaylistPath: liveTrickplayPlaylistPath,
                        trickplayFrameLoader: trickplayFrameLoader,
                        onFullscreen: onRequestDismiss,
                        onDismiss: onRequestDismiss
                    )
                } else {
                    VideoFullscreenPreparationView(
                        title: liveTitle,
                        phase: livePhase,
                        isReadyToPlay: false,
                        playRequested: livePlayRequested,
                        resumeSeconds: liveResumeSeconds,
                        onResume: onResume,
                        onRestart: onRestart,
                        onDismiss: onRequestDismiss
                    )
                }
            }
        }
    }
#endif

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
