import AVFoundation
import SwiftUI

#if os(tvOS)
    import AVKit

    struct PrismediaVideoPlayerView: View {
        let controller: VideoPlaybackController
        let title: String
        let isInteractive: Bool
        let isExpanded: Bool
        var badges: [VideoPlaybackBadge] = []
        let onFullscreen: () -> Void
        var onDismiss: (() -> Void)?

        var body: some View {
            ZStack {
                VideoPlayer(player: controller.player)
                VideoSubtitlePlaybackOverlay(
                    assContents: controller.activeAssSubtitleContents,
                    content: controller.activeSubtitleContent,
                    appearance: controller.subtitleAppearance,
                    player: controller.player
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .accessibilityIdentifier("video-player.surface")
        }
    }

#else
    struct PrismediaVideoPlayerView: View {
        let controller: VideoPlaybackController
        let title: String
        let isInteractive: Bool
        let isExpanded: Bool
        var badges: [VideoPlaybackBadge] = []
        let onFullscreen: () -> Void
        var onDismiss: (() -> Void)?

        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @State private var controlsVisible = true

        private var showsExpandedChrome: Bool { isExpanded || verticalSizeClass == .compact }

        var body: some View {
            ZStack {
                Color.black
                VideoPlayerRenderSurface(controller: controller)
                    .allowsHitTesting(false)

                gestureLayer

                VideoSubtitlePlaybackOverlay(
                    assContents: controller.activeAssSubtitleContents,
                    content: controller.activeSubtitleContent,
                    appearance: controller.subtitleAppearance,
                    player: controller.player,
                    additionalBottomInset: controlsVisible && showsExpandedChrome ? 16 : 0
                )

                chrome
                    .opacity(controlsVisible || !isInteractive ? 1 : 0)
                    .allowsHitTesting(controlsVisible || !isInteractive)

            }
            .contentShape(Rectangle())
            .simultaneousGesture(fullscreenDismissGesture)
            .task(id: controller.isPlaying) { await scheduleAutoHide() }
            .animation(.easeOut(duration: 0.18), value: controlsVisible)
            .accessibilityIdentifier("video-player.surface")
        }

        private var gestureLayer: some View {
            HStack(spacing: 0) {
                VideoGestureRegion(controller: controller, side: .left, onSingleTap: revealOrToggleChrome)
                VideoGestureRegion(controller: controller, side: .right, onSingleTap: revealOrToggleChrome)
            }
            .allowsHitTesting(isInteractive)
        }

        private var fullscreenDismissGesture: some Gesture {
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard isExpanded,
                        VideoPlayerGesturePolicy.shouldDismissFullscreen(translation: value.translation)
                    else { return }
                    onDismiss?()
                }
        }

        private var chrome: some View {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(showsExpandedChrome ? 0.58 : 0.28), .clear, .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                if isInteractive {
                    transportControls
                } else {
                    VStack(spacing: PrismediaSpacing.medium) {
                        ProgressView().tint(artworkPrimaryAccent)
                        Text("Preparing video…")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }

                VStack(spacing: 0) {
                    if showsExpandedChrome { expandedHeader }
                    Spacer()
                    if isInteractive { bottomChrome }
                }
                .padding(showsExpandedChrome ? 20 : 10)
            }
        }

        private var transportControls: some View {
            GlassEffectContainer(spacing: showsExpandedChrome ? 34 : 22) {
                HStack(spacing: showsExpandedChrome ? 34 : 22) {
                    transportButton(systemImage: "gobackward.10", size: showsExpandedChrome ? 44 : 36) {
                        controller.skip(by: -10)
                    }
                    transportButton(
                        systemImage: controller.isPlaying || controller.isWaiting ? "pause.fill" : "play.fill",
                        size: showsExpandedChrome ? 62 : 50,
                        prominent: true,
                        action: controller.togglePlayback
                    )
                    .accessibilityLabel(
                        controller.isPlaying || controller.isWaiting ? "Pause" : "Play"
                    )
                    .accessibilityIdentifier(
                        controller.isPlaying || controller.isWaiting
                            ? "video-detail.pause"
                            : "video-detail.play"
                    )
                    transportButton(systemImage: "goforward.10", size: showsExpandedChrome ? 44 : 36) {
                        controller.skip(by: 10)
                    }
                }
            }
        }

        private func transportButton(
            systemImage: String,
            size: CGFloat,
            prominent: Bool = false,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: prominent ? size * 0.38 : size * 0.34, weight: .bold))
                    .frame(width: size, height: size)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .glassEffect(
                prominent
                    ? .regular.tint(artworkPrimaryAccent).interactive()
                    : .regular.interactive(),
                in: .circle
            )
        }

        private var expandedHeader: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(artworkPrimaryAccent)
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(PrismediaColor.onMedia)
                }
                Spacer()
                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Exit Full Screen")
                }
            }
        }

        private var bottomChrome: some View {
            VStack(spacing: PrismediaSpacing.extraSmall) {
                if showsExpandedChrome, !badges.isEmpty {
                    VideoStatusChips(badges: badges, overlaysVideo: true)
                }
                VideoPlaybackTimeline(controller: controller)
                HStack {
                    Text(VideoPlaybackPresentation.clockTime(controller.currentTime))
                    Spacer()
                    Text(
                        "−\(VideoPlaybackPresentation.clockTime(max(0, controller.duration - controller.currentTime)))")
                    playbackOptionsMenu
                    #if os(iOS)
                        if controller.renderer == .native {
                            bottomChromeButton(
                                systemImage: "pip.enter",
                                accessibilityLabel: "Start Picture in Picture",
                                action: controller.startPictureInPicture
                            )
                        }
                    #endif
                    bottomChromeButton(
                        systemImage: isExpanded
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right",
                        accessibilityLabel: isExpanded ? "Exit Full Screen" : "Enter Full Screen",
                        action: onFullscreen
                    )
                }
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
            }
        }

        private var playbackOptionsMenu: some View {
            Menu {
                Menu("Video Size", systemImage: "rectangle.arrowtriangle.2.outward") {
                    ForEach(VideoScalingMode.allCases) { mode in
                        menuChoice(mode.label, selected: controller.videoScalingMode == mode) {
                            controller.setVideoScalingMode(mode)
                        }
                    }
                }

                Menu("Subtitles", systemImage: "captions.bubble") {
                    ForEach(controller.subtitleChoices) { choice in
                        menuChoice(
                            choice.title,
                            selected: controller.selectedSubtitleChoiceID == choice.id
                        ) {
                            Task { await controller.selectSubtitle(id: choice.id) }
                        }
                    }
                }

                Menu("Audio", systemImage: "waveform") {
                    if controller.audioChoices.isEmpty {
                        menuChoice("Default", selected: true) {}
                            .disabled(true)
                    } else {
                        ForEach(controller.audioChoices) { choice in
                            menuChoice(
                                choice.title,
                                selected: controller.selectedAudioChoiceID == choice.id
                            ) {
                                Task { await controller.selectAudio(id: choice.id) }
                            }
                        }
                    }
                }

                Menu("Playback Speed", systemImage: "speedometer") {
                    ForEach(VideoPlaybackSettings.availableRates, id: \.self) { rate in
                        menuChoice(
                            VideoPlaybackSettings.label(for: rate),
                            selected: controller.playbackRate == rate
                        ) {
                            controller.setPlaybackRate(rate)
                        }
                    }
                }
            } label: {
                bottomChromeIcon(systemImage: "ellipsis")
            }
            .menuActionDismissBehavior(.enabled)
            .accessibilityLabel("Playback Options")
        }

        private func menuChoice(
            _ title: String,
            selected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                if selected {
                    Label(title, systemImage: "checkmark")
                } else {
                    Text(title)
                }
            }
        }

        private func bottomChromeButton(
            systemImage: String,
            accessibilityLabel: String,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) { bottomChromeIcon(systemImage: systemImage) }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
        }

        private func bottomChromeIcon(systemImage: String) -> some View {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .frame(
                    width: VideoPlayerControlMetrics.bottomVisualWidth,
                    height: VideoPlayerControlMetrics.bottomVisualHeight
                )
                .glassEffect(.regular.interactive(), in: .capsule)
                .frame(
                    width: VideoPlayerControlMetrics.bottomHitSize,
                    height: VideoPlayerControlMetrics.bottomHitSize
                )
                .contentShape(Rectangle())
        }

        private func revealOrToggleChrome() {
            guard isInteractive else { return }
            controlsVisible.toggle()
            if controlsVisible, controller.isPlaying {
                Task { await scheduleAutoHide() }
            }
        }

        private func scheduleAutoHide() async {
            guard
                VideoPlayerChromePolicy.shouldAutoHide(
                    isPlaying: controller.isPlaying,
                    optionsPresented: false
                )
            else {
                controlsVisible = true
                return
            }
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled,
                VideoPlayerChromePolicy.shouldAutoHide(
                    isPlaying: controller.isPlaying,
                    optionsPresented: false
                )
            else { return }
            controlsVisible = false
        }
    }

    #if DEBUG
        #Preview("Custom Native Video Chrome") {
            let id = UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!
            let controller = VideoPlaybackController(videoID: id, service: VideoPlaybackPreviewService())
            PrismediaVideoPlayerView(
                controller: controller,
                title: "Signal in the Static",
                isInteractive: true,
                isExpanded: false,
                onFullscreen: {}
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .background(Color.black)
        }
    #endif
#endif
