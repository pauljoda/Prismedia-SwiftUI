#if os(tvOS)
    import SwiftUI

    struct TVCompatibilityPlayerView: View {
        let controller: VideoPlaybackController
        let request: VideoCompatibilityPlaybackRequest
        let title: String
        let onRequestDismiss: () -> Void

        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @State private var controlsVisible = true
        @State private var controlsDismissGeneration = 0
        @FocusState private var playerSurfaceFocused: Bool
        @FocusState private var focusedPlaybackMenu: String?

        var body: some View {
            ZStack {
                Color.black
                TVVLCPlayerController(request: request, controller: controller)
                    .ignoresSafeArea()

                if let subtitleContent = controller.activeSubtitleContent {
                    VideoSubtitleOverlay(
                        content: subtitleContent,
                        appearance: controller.subtitleAppearance,
                        additionalBottomInset: controlsVisible ? 240 : 0
                    )
                    .ignoresSafeArea()
                }

                if controlsVisible {
                    chrome
                        .transition(.opacity)
                }

                if controller.isWaiting {
                    ProgressView()
                        .controlSize(.large)
                        .tint(artworkPrimaryAccent)
                        .accessibilityLabel("Buffering")
                }
            }
            .background(Color.black)
            .focusable()
            .focused($playerSurfaceFocused)
            .focusEffectDisabled()
            .onTapGesture(perform: toggleControls)
            .onPlayPauseCommand {
                revealControls()
                controller.togglePlayback()
            }
            .onMoveCommand(perform: handleMoveCommand)
            .onExitCommand(perform: onRequestDismiss)
            .onChange(of: controller.isPlaying, initial: true) { _, _ in
                revealControls()
            }
            .onChange(of: focusedPlaybackMenu) { _, _ in
                revealControls()
            }
            .onAppear {
                playerSurfaceFocused = true
            }
            .task(id: controlsDismissGeneration) {
                guard controller.isPlaying, focusedPlaybackMenu == nil else { return }
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled, controller.isPlaying, focusedPlaybackMenu == nil else { return }
                controlsVisible = false
            }
            .animation(.easeOut(duration: 0.18), value: controlsVisible)
            .accessibilityIdentifier("video-player.compatibility-surface")
        }

        private var chrome: some View {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.58), .clear, .black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    header
                    Spacer()
                    bottomChrome
                }
                .padding(.horizontal, 64)
                .padding(.vertical, 42)
            }
        }

        private var header: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text("NOW PLAYING")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(artworkPrimaryAccent)
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(PrismediaColor.onMedia)
                }
                Spacer()
                Text("VLC")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, PrismediaSpacing.medium)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .glassEffect(.regular, in: .capsule)
            }
        }

        private var bottomChrome: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                HStack(alignment: .center, spacing: PrismediaSpacing.large) {
                    if !controller.badges.isEmpty {
                        VideoStatusChips(badges: controller.badges, overlaysVideo: true)
                    }
                    Spacer(minLength: PrismediaSpacing.section)
                    playbackMenus
                }

                TVVideoPlaybackTimeline(controller: controller)

                HStack(spacing: PrismediaSpacing.medium) {
                    Text(VideoPlaybackPresentation.clockTime(controller.currentTime))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.84))
                    Spacer()
                    Text(
                        "−\(VideoPlaybackPresentation.clockTime(max(0, controller.duration - controller.currentTime)))"
                    )
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(PrismediaColor.onMedia.opacity(0.84))
                }
            }
        }

        private func toggleControls() {
            if controlsVisible {
                focusedPlaybackMenu = nil
                playerSurfaceFocused = true
            }
            controlsVisible.toggle()
            controlsDismissGeneration += 1
        }

        private func revealControls() {
            controlsVisible = true
            controlsDismissGeneration += 1
        }

        private func handleMoveCommand(_ direction: MoveCommandDirection) {
            revealControls()
            if let focusedPlaybackMenu {
                switch direction {
                case .left:
                    self.focusedPlaybackMenu = switch focusedPlaybackMenu {
                    case "subtitles": "audio"
                    case "speed": "subtitles"
                    default: "audio"
                    }
                case .right:
                    self.focusedPlaybackMenu = switch focusedPlaybackMenu {
                    case "audio": "subtitles"
                    case "subtitles": "speed"
                    default: "speed"
                    }
                case .down:
                    self.focusedPlaybackMenu = nil
                    playerSurfaceFocused = true
                default:
                    break
                }
                return
            }
            switch direction {
            case .left:
                controller.skip(by: -10)
            case .right:
                controller.skip(by: 10)
            case .up:
                focusedPlaybackMenu = "audio"
            default:
                break
            }
        }

        private var playbackMenus: some View {
            HStack(spacing: PrismediaSpacing.extraLarge) {
                audioMenu
                subtitleMenu
                playbackSpeedMenu
            }
            .prismediaFocusSection()
        }

        private var audioMenu: some View {
            Menu {
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
            } label: {
                playbackMenuLabel(systemImage: "waveform")
            }
            .focused($focusedPlaybackMenu, equals: "audio")
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Audio Tracks")
        }

        private var subtitleMenu: some View {
            Menu {
                if controller.subtitleChoices.isEmpty {
                    Text("No Subtitles Available")
                } else {
                    ForEach(controller.subtitleChoices) { choice in
                        menuChoice(
                            choice.title,
                            selected: controller.selectedSubtitleChoiceID == choice.id
                        ) {
                            Task { await controller.selectSubtitle(id: choice.id) }
                        }
                    }
                }
            } label: {
                playbackMenuLabel(systemImage: "captions.bubble")
            }
            .focused($focusedPlaybackMenu, equals: "subtitles")
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Subtitles")
        }

        private var playbackSpeedMenu: some View {
            Menu {
                ForEach(VideoPlaybackSettings.availableRates, id: \.self) { rate in
                    menuChoice(
                        VideoPlaybackSettings.label(for: rate),
                        selected: controller.playbackRate == rate
                    ) {
                        controller.setPlaybackRate(rate)
                    }
                }
            } label: {
                playbackMenuLabel(systemImage: "speedometer")
            }
            .focused($focusedPlaybackMenu, equals: "speed")
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Playback Speed")
        }

        private func playbackMenuLabel(systemImage: String) -> some View {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .frame(
                    width: VideoPlayerControlMetrics.bottomVisualWidth,
                    height: VideoPlayerControlMetrics.bottomVisualHeight
                )
                .glassEffect(.regular, in: .circle)
                .frame(
                    width: VideoPlayerControlMetrics.bottomHitSize,
                    height: VideoPlayerControlMetrics.bottomHitSize
                )
                .contentShape(Circle())
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

    }

    #if DEBUG
        #Preview("TV Compatibility Player") {
            TVCompatibilityPlayerView(
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                ),
                request: VideoCompatibilityPlaybackRequest(
                    url: URL(string: "https://example.com/video.mkv")!,
                    resumeTime: 42,
                    playbackRate: 1,
                    audioStreams: []
                ),
                title: "Signal in the Static",
                onRequestDismiss: {}
            )
        }
    #endif
#endif
