#if os(iOS)
import SwiftUI

/// Root view of the UIKit-presented fullscreen player. Self-sufficient by
/// design: while the player covers the launching page, that page's hierarchy
/// stops rendering, so nothing may depend on values piped through it. This
/// view reads the preparation coordinator and playback controller directly —
/// both are `@Observable`, and the hosting controller has its own render
/// loop — and dismisses through UIKit, never through the covered page.
struct VideoFullscreenHostedRoot: View {
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

#if DEBUG
#Preview("Fullscreen Hosted Root") {
    VideoFullscreenHostedRoot(
        preparation: nil,
        fallbackController: nil,
        fallbackTitle: "Signal in the Static",
        requiresExplicitPlay: true,
        fallbackPhase: .loading,
        fallbackPlayRequested: false,
        fallbackResumeSeconds: 734,
        trickplayPlaylistPath: nil,
        trickplayFrameLoader: nil,
        orientationController: VideoFullscreenOrientationController(),
        onResume: {},
        onRestart: {},
        onRequestDismiss: {}
    )
}
#endif
#endif
