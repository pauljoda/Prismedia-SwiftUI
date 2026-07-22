#if os(tvOS)
    import SwiftUI

    struct TVPlayerView: View {
        let controller: VideoPlaybackController
        let compatibilityRequest: VideoCompatibilityPlaybackRequest?
        let title: String
        let trickplayPlaylistPath: String?
        let trickplayFrameLoader: (any TrickplayFrameLoading)?
        let onRequestDismiss: () -> Void

        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @State private var controlsVisible = true
        @State private var controlsDismissGeneration = 0
        @State private var hasStartedAutoDismiss = false
        @State private var awaitsAutoDismissAfterResume = false
        @State private var optionsFocusEnabled = false
        @State private var trickplayFrames: [TrickplayPlaylist.Frame] = []
        @State private var previewTime: Double?
        @State private var seekOriginTime: Double?
        @State private var scrubPanOrigin = 0.0
        @State private var isScrubbing = false
        @State private var scanSide: VideoPlayerGestureSide?
        @State private var scanRate = VideoPlaybackScanPolicy.rates[0]
        @State private var scanRunGeneration = 0
        @State private var scanCommitGeneration = 0
        @FocusState private var focusedControl: TVCompatibilityPlayerFocusTarget?

        var body: some View {
            ZStack {
                Color.black
                TVPlayerRenderSurface(
                    controller: controller,
                    compatibilityRequest: compatibilityRequest
                )
                .ignoresSafeArea()

                if compatibilityRequest == nil {
                    VideoSubtitlePlaybackOverlay(
                        assContents: controller.activeAssSubtitleContents,
                        content: controller.activeSubtitleContent,
                        appearance: controller.subtitleAppearance,
                        player: controller.player,
                        additionalBottomInset: controlsVisible ? 240 : 0
                    )
                    .ignoresSafeArea()
                } else if let subtitleContent = controller.activeSubtitleContent {
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
                } else {
                    hiddenPlaybackInteractionSurface
                }

                if controller.isWaiting {
                    ProgressView()
                        .controlSize(.large)
                        .tint(artworkPrimaryAccent)
                        .accessibilityLabel("Buffering")
                }

                if let scanSide {
                    TVPlaybackScanIndicator(side: scanSide, rate: scanRate)
                }
            }
            .background(Color.black)
            .prismediaFocusSection()
            .onPlayPauseCommand(perform: handlePlayPauseCommand)
            .onExitCommand(perform: handleExitCommand)
            .onChange(of: controller.isPlaying) { wasPlaying, isPlaying in
                if wasPlaying, !isPlaying {
                    revealControlsAfterPause()
                }
                handlePlaybackStateChange(isPlaying: isPlaying)
            }
            .onAppear {
                moveFocus(to: .timeline)
                handlePlaybackStateChange(isPlaying: controller.isPlaying)
            }
            .onDisappear {
                cancelSeekPreview()
            }
            .task(id: controlsDismissGeneration) {
                guard canAutoDismissControls else { return }
                try? await Task.sleep(for: controlsAutoDismissDelay)
                guard !Task.isCancelled, canAutoDismissControls else { return }
                optionsFocusEnabled = false
                controlsVisible = false
            }
            .task(id: scanRunGeneration) {
                await runScanPreview()
            }
            .task(id: scanCommitGeneration) {
                guard scanSide != nil else { return }
                try? await Task.sleep(for: scanSettleDelay)
                guard !Task.isCancelled, scanSide != nil else { return }
                finishScan(resumePlayback: true)
            }
            .task(id: trickplayPlaylistPath) {
                await loadTrickplayFrames()
            }
            .animation(.easeOut(duration: 0.18), value: controlsVisible)
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
                if !controller.badges.isEmpty {
                    VideoStatusChips(
                        badges: controller.badges,
                        overlaysVideo: true,
                        contentHorizontalPadding: 0,
                        scrollAnchor: .trailing
                    )
                    .frame(maxWidth: 760, alignment: .trailing)
                }
            }
        }

        private var bottomChrome: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                playbackOptionButtons
                    .frame(maxWidth: .infinity, alignment: .trailing)

                playbackTimeline

                HStack(spacing: PrismediaSpacing.medium) {
                    Text(VideoPlaybackPresentation.clockTime(displayedTime))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.84))
                    Spacer()
                    Text("−\(VideoPlaybackPresentation.clockTime(max(0, controller.duration - displayedTime)))")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.84))
                }
            }
        }

        private var playbackTimeline: some View {
            TVPlaybackScrubber(
                controlsVisible: controlsVisible,
                isFocusEnabled: !optionsFocusEnabled,
                isGrabbed: isScrubbing,
                isScrollingEnabled: isScrubbing,
                onFocusChange: handleTimelineFocusChange,
                onRevealControls: revealControls,
                onMoveToOptions: moveToPlaybackOptions,
                onPrimaryAction: handlePrimaryAction,
                onHorizontalPress: handleHorizontalPress,
                onPanBegan: beginPan,
                onPanChanged: updatePan,
                onPanEnded: endPan
            ) {
                TVVideoPlaybackTimeline(
                    currentTime: displayedTime,
                    duration: controller.duration,
                    originTime: seekOriginTime,
                    isFocused: focusedControl == .timeline,
                    isSeeking: isSeeking,
                    previewFrame: trickplayFrame
                )
            }
            .frame(height: 72)
            .focused($focusedControl, equals: .timeline)
            .focusEffectDisabled()
            .accessibilityLabel("Playback timeline")
            .accessibilityValue(timelineAccessibilityValue)
            .accessibilityIdentifier("video-player.compatibility-surface")
        }

        private var hiddenPlaybackInteractionSurface: some View {
            TVPlaybackScrubber(
                controlsVisible: false,
                isFocusEnabled: true,
                isGrabbed: false,
                isScrollingEnabled: false,
                onFocusChange: handleTimelineFocusChange,
                onRevealControls: revealControls,
                onMoveToOptions: moveToPlaybackOptions,
                onPrimaryAction: handlePrimaryAction,
                onHorizontalPress: handleHorizontalPress,
                onPanBegan: {},
                onPanChanged: { _ in },
                onPanEnded: {}
            ) {
                Color.clear
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focused($focusedControl, equals: .timeline)
            .focusEffectDisabled()
            .accessibilityLabel("Playback timeline")
            .accessibilityValue(timelineAccessibilityValue)
            .accessibilityIdentifier("video-player.compatibility-surface")
        }

        private var playbackOptionButtons: some View {
            GlassEffectContainer(spacing: PrismediaSpacing.large) {
                HStack(spacing: PrismediaSpacing.large) {
                    TVPlaybackOptionMenuButton(
                        controller: controller,
                        menu: .audio,
                        focusTarget: .audio,
                        systemImage: "waveform",
                        focusedControl: $focusedControl,
                        onMove: {
                            handlePlaybackOptionsMove(from: .audio, direction: $0)
                        },
                        onInteraction: revealControls
                    )
                    .equatable()
                    TVPlaybackOptionMenuButton(
                        controller: controller,
                        menu: .subtitles,
                        focusTarget: .subtitles,
                        systemImage: "captions.bubble",
                        focusedControl: $focusedControl,
                        onMove: {
                            handlePlaybackOptionsMove(from: .subtitles, direction: $0)
                        },
                        onInteraction: revealControls
                    )
                    .equatable()
                    TVPlaybackOptionMenuButton(
                        controller: controller,
                        menu: .speed,
                        focusTarget: .speed,
                        systemImage: "speedometer",
                        focusedControl: $focusedControl,
                        onMove: {
                            handlePlaybackOptionsMove(from: .speed, direction: $0)
                        },
                        onInteraction: revealControls
                    )
                    .equatable()
                }
            }
            .prismediaFocusSection()
        }

        private var displayedTime: Double {
            previewTime ?? controller.currentTime
        }

        private var trickplayFrame: TrickplayPlaylist.Frame? {
            TrickplayPlaylist(frames: trickplayFrames).frame(at: displayedTime)
        }

        private var timelineAccessibilityValue: String {
            let position = VideoPlaybackTimelineAccessibility.value(
                currentTime: displayedTime,
                duration: controller.duration
            )
            if isScrubbing { return "\(position), Scrubbing" }
            if let scanSide {
                let action = scanSide == .left ? "Rewinding" : "Fast forwarding"
                return "\(position), \(action) at \(Int(scanRate)) times"
            }
            return position
        }

        private var isSeeking: Bool {
            isScrubbing || scanSide != nil
        }

        private var canAutoDismissControls: Bool {
            VideoPlayerChromePolicy.shouldAutoHide(
                isPlaying: controller.isPlaying,
                optionsPresented: optionsFocusEnabled,
                isSeeking: isSeeking
            )
        }

        private var controlsAutoDismissDelay: Duration {
            #if DEBUG
                PrismediaUITestBootstrap.videoControlsAutoHideDelay()
                    ?? VideoPlayerChromePolicy.tvAutoHideDelay
            #else
                VideoPlayerChromePolicy.tvAutoHideDelay
            #endif
        }

        private var scanSettleDelay: Duration {
            #if DEBUG
                PrismediaUITestBootstrap.videoScanSettleDelay() ?? .milliseconds(900)
            #else
                .milliseconds(900)
            #endif
        }

        private func revealControls() {
            controlsVisible = true
            resetControlsDismissTimer()
        }

        private func resetControlsDismissTimer() {
            controlsDismissGeneration += 1
        }

        private func handlePlaybackStateChange(isPlaying: Bool) {
            guard isPlaying else { return }
            let shouldArmTimer = !hasStartedAutoDismiss || awaitsAutoDismissAfterResume
            hasStartedAutoDismiss = true
            awaitsAutoDismissAfterResume = false
            if shouldArmTimer { resetControlsDismissTimer() }
        }

        private func revealControlsAfterPause() {
            Task { @MainActor in
                await Task.yield()
                guard !controller.isPlaying, !controller.isWaiting else { return }
                revealControls()
            }
        }

        private func moveToPlaybackOptions() {
            revealControls()
            optionsFocusEnabled = true
            Task { @MainActor in
                await Task.yield()
                moveFocus(to: .audio)
            }
        }

        private func handlePlaybackOptionsMove(
            from source: TVCompatibilityPlayerFocusTarget,
            direction: MoveCommandDirection
        ) {
            let target: TVCompatibilityPlayerFocusTarget?
            switch (source, direction) {
            case (.audio, .right): target = .subtitles
            case (.subtitles, .left): target = .audio
            case (.subtitles, .right): target = .speed
            case (.speed, .left): target = .subtitles
            case (_, .down): target = .timeline
            case (.audio, .left): target = .audio
            case (.speed, .right): target = .speed
            default: target = nil
            }
            if target == .timeline {
                optionsFocusEnabled = false
                Task { @MainActor in
                    await Task.yield()
                    moveFocus(to: .timeline)
                }
            } else if let target {
                moveFocus(to: target)
            }
            revealControls()
        }

        private func handleTimelineFocusChange(_ isFocused: Bool) {
            Task { @MainActor in
                guard !optionsFocusEnabled else { return }
                if isFocused {
                    guard focusedControl != .timeline else { return }
                    focusedControl = .timeline
                } else if focusedControl == .timeline {
                    focusedControl = nil
                }
            }
        }

        private func handlePrimaryAction() {
            revealControls()
            moveFocus(to: .timeline)

            if scanSide != nil {
                finishScan(resumePlayback: true)
            } else if controller.isPlaying || controller.isWaiting {
                controller.pause()
            } else if isScrubbing {
                commitScrub()
            } else {
                beginScrub()
            }
        }

        private func handlePlayPauseCommand() {
            revealControls()
            moveFocus(to: .timeline)
            if scanSide != nil {
                finishScan(resumePlayback: true)
                return
            }
            if isScrubbing {
                commitScrub(resumePlayback: true)
                return
            }
            if !controller.isPlaying, !controller.isWaiting {
                awaitsAutoDismissAfterResume = true
            }
            controller.togglePlayback()
        }

        private func handleExitCommand() {
            guard controlsVisible else {
                onRequestDismiss()
                return
            }
            hideControls()
        }

        private func handleHorizontalPress(_ side: VideoPlayerGestureSide) {
            if isScrubbing {
                previewTime = boundedTime(displayedTime + (side == .left ? -10 : 10))
                revealControls()
                return
            }

            if controller.isPlaying || controller.isWaiting {
                controller.skip(by: side == .left ? -10 : 10)
                if controlsVisible { resetControlsDismissTimer() }
                return
            }

            beginOrAdvanceScan(on: side)
        }

        private func beginOrAdvanceScan(on side: VideoPlayerGestureSide) {
            let rate = VideoPlaybackScanPolicy.nextRate(
                currentSide: scanSide,
                currentRate: scanRate,
                direction: side
            )
            if scanSide == nil {
                seekOriginTime = controller.currentTime
                previewTime = controller.currentTime
            }
            scanSide = side
            scanRate = rate
            scanRunGeneration += 1
            scanCommitGeneration += 1
            revealControls()
        }

        private func runScanPreview() async {
            guard let side = scanSide else { return }
            let rate = scanRate
            let direction = side == .left ? -1.0 : 1.0
            while !Task.isCancelled, scanSide == side, scanRate == rate {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, scanSide == side, scanRate == rate else { return }
                previewTime = boundedTime(displayedTime + direction * Double(rate) * 0.05)
            }
        }

        private func finishScan(resumePlayback: Bool) {
            guard scanSide != nil, let target = previewTime else { return }
            clearSeekPreview()
            controller.seek(to: target) { finished in
                guard finished, resumePlayback else { return }
                awaitsAutoDismissAfterResume = true
                controller.play()
            }
        }

        private func beginScrub() {
            guard controller.duration > 0 else { return }
            controller.pause()
            seekOriginTime = controller.currentTime
            previewTime = controller.currentTime
            scrubPanOrigin = controller.currentTime
            isScrubbing = true
            revealControls()
        }

        private func commitScrub(resumePlayback: Bool = false) {
            guard isScrubbing, let target = previewTime else { return }
            clearSeekPreview()
            controller.seek(to: target) { finished in
                guard finished, resumePlayback else { return }
                awaitsAutoDismissAfterResume = true
                controller.play()
            }
        }

        private func beginPan() {
            guard isScrubbing else { return }
            scrubPanOrigin = displayedTime
            revealControls()
        }

        private func updatePan(_ translation: CGFloat) {
            guard isScrubbing, controller.duration > 0 else { return }
            previewTime = VideoPlaybackScrubPolicy.targetTime(
                origin: scrubPanOrigin,
                translation: Double(translation),
                duration: controller.duration
            )
            resetControlsDismissTimer()
        }

        private func endPan() {
            guard isScrubbing else { return }
            scrubPanOrigin = displayedTime
            revealControls()
        }

        private func cancelSeekPreview() {
            clearSeekPreview()
        }

        private func clearSeekPreview() {
            isScrubbing = false
            scanSide = nil
            scanRate = VideoPlaybackScanPolicy.rates[0]
            previewTime = nil
            seekOriginTime = nil
            scanRunGeneration += 1
            scanCommitGeneration += 1
        }

        private func hideControls() {
            cancelSeekPreview()
            optionsFocusEnabled = false
            controlsVisible = false
            moveFocus(to: .timeline)
        }

        private func boundedTime(_ time: Double) -> Double {
            max(0, min(time, controller.duration > 0 ? controller.duration : time))
        }

        private func loadTrickplayFrames() async {
            trickplayFrames = []
            guard let trickplayPlaylistPath, let trickplayFrameLoader else { return }
            let frames = await trickplayFrameLoader.loadFrames(
                playlistPath: trickplayPlaylistPath
            )
            guard !Task.isCancelled, self.trickplayPlaylistPath == trickplayPlaylistPath else {
                return
            }
            trickplayFrames = frames
        }

        private func moveFocus(to target: TVCompatibilityPlayerFocusTarget) {
            focusedControl = nil
            Task { @MainActor in
                await Task.yield()
                focusedControl = target
            }
        }
    }

    #if DEBUG
        #Preview("TV Player") {
            TVPlayerView(
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                ),
                compatibilityRequest: nil,
                title: "Signal in the Static",
                trickplayPlaylistPath: nil,
                trickplayFrameLoader: nil,
                onRequestDismiss: {}
            )
        }
    #endif
#endif
