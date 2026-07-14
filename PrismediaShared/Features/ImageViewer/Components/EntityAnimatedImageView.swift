import SwiftUI

struct EntityAnimatedImageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPausedByUser = false
    @State private var hasExplicitPlaybackRequest = false
    @State private var playbackStartDate = Date()
    @State private var frozenElapsedTime = 0.0

    let sequence: AnimatedImageSequence
    let title: String
    private let isPlaybackActive: Bool
    private let interaction: EntityImageMediaInteraction
    private let showsControls: Bool

    init(
        sequence: AnimatedImageSequence,
        title: String,
        isPlaybackActive: Bool = true,
        interaction: EntityImageMediaInteraction = .viewer,
        showsControls: Bool = true
    ) {
        self.sequence = sequence
        self.title = title
        self.isPlaybackActive = isPlaybackActive
        self.interaction = interaction
        self.showsControls = showsControls
    }

    var body: some View {
        playbackSurface
    }

    private var playbackSurface: some View {
        Group {
            if interaction.allowsZoom {
                viewerSurface
            } else {
                feedSurface
            }
        }
        .onChange(of: shouldPlay, initial: true) { wasPlaying, isPlaying in
            playbackStateDidChange(from: wasPlaying, to: isPlaying)
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled { hasExplicitPlaybackRequest = false }
        }
    }

    private var viewerSurface: some View {
        animatedFrame
            .toolbar {
                #if os(iOS)
                    if showsControls {
                        ToolbarItem(placement: .bottomBar) {
                            playbackButton
                        }
                    }
                #elseif os(macOS)
                    if showsControls {
                        ToolbarItem(placement: .primaryAction) {
                            playbackButton
                        }
                    }
                #endif
            }
            .accessibilityAction(named: "Toggle animation", togglePlayback)
    }

    private var playbackButton: some View {
        Button(
            shouldPlay ? "Pause animation" : "Play animation",
            systemImage: shouldPlay ? "pause.fill" : "play.fill",
            action: togglePlayback
        )
    }

    private var feedSurface: some View {
        animatedFrame
            .accessibilityLabel(title)
            .accessibilityValue(shouldPlay ? "Playing" : "Paused")
    }

    private var animatedFrame: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: !shouldPlay
            )
        ) { context in
            if let frame = sequence.frame(at: elapsedTime(at: context.date)) {
                frameView(frame)
            }
        }
    }

    @ViewBuilder
    private func frameView(_ frame: CGImage) -> some View {
        if interaction.allowsZoom {
            EntityImageZoomView(
                image: Image(decorative: frame, scale: 1, orientation: .up),
                title: title,
                showsControls: showsControls
            )
        } else {
            Image(decorative: frame, scale: 1, orientation: .up)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }

    private var shouldPlay: Bool {
        EntityImageAutoplayPolicy.shouldPlay(
            isVisible: isPlaybackActive,
            isPausedByUser: isPausedByUser,
            reduceMotion: reduceMotion,
            isSceneActive: scenePhase == .active,
            isExplicitPlaybackRequested: hasExplicitPlaybackRequest
        )
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        guard shouldPlay else { return frozenElapsedTime }
        return frozenElapsedTime + max(0, date.timeIntervalSince(playbackStartDate))
    }

    private func togglePlayback() {
        if reduceMotion, !hasExplicitPlaybackRequest {
            hasExplicitPlaybackRequest = true
            isPausedByUser = false
        } else {
            isPausedByUser.toggle()
        }
    }

    private func playbackStateDidChange(from wasPlaying: Bool, to isPlaying: Bool) {
        guard wasPlaying != isPlaying else { return }
        let now = Date()
        if wasPlaying {
            frozenElapsedTime += max(0, now.timeIntervalSince(playbackStartDate))
        } else {
            playbackStartDate = now
        }
    }
}

#if DEBUG
    #Preview("Animated Image") {
        if let sequence = AnimatedImageSequence.decode(
            data: EntityImageViewerPreviewData.pngData
        ) {
            EntityAnimatedImageView(sequence: sequence, title: "Animated Preview")
                .background(PrismediaColor.background)
        }
    }
#endif
