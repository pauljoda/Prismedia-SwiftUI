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
        @State private var activeOptionsMenu: TVPlaybackOptionsMenu?
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

                timelineInteractionSurface

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
            .confirmationDialog(
                activeOptionsMenu?.title ?? "Playback Options",
                isPresented: optionsMenuPresented,
                titleVisibility: .visible
            ) {
                optionsMenuActions
            }
            .onChange(of: controller.isPlaying) { _, isPlaying in
                if isPlaying { resetControlsDismissTimer() }
            }
            .onChange(of: focusedControl) { previousControl, focusedControl in
                guard focusedControl != previousControl else { return }
                if focusedControl != nil { revealControls() }
            }
            .onAppear {
                moveFocus(to: .timeline)
            }
            .onDisappear {
                cancelSeekPreview()
            }
            .task(id: controlsDismissGeneration) {
                guard canAutoDismissControls else { return }
                try? await Task.sleep(for: controlsAutoDismissDelay)
                guard !Task.isCancelled, canAutoDismissControls else { return }
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
                    playbackOptionButtons
                }

                TVVideoPlaybackTimeline(
                    currentTime: displayedTime,
                    duration: controller.duration,
                    originTime: seekOriginTime,
                    isSeeking: isSeeking,
                    previewURL: request.url
                )

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

        private var timelineInteractionSurface: some View {
            TVPlaybackScrubber(
                controlsVisible: controlsVisible,
                isGrabbed: isScrubbing,
                onFocusChange: handleTimelineFocusChange,
                onRevealControls: revealControls,
                onMoveToOptions: moveToPlaybackOptions,
                onPrimaryAction: handlePrimaryAction,
                onHorizontalPress: handleHorizontalPress,
                onPanBegan: beginPan,
                onPanChanged: updatePan,
                onPanEnded: endPan
            )
            .frame(height: 132)
            .padding(.horizontal, 64)
            .padding(.bottom, 42)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .focused($focusedControl, equals: .timeline)
            .focusEffectDisabled()
            .accessibilityLabel("Playback timeline")
            .accessibilityValue(
                timelineAccessibilityValue
            )
            .accessibilityIdentifier("video-player.compatibility-surface")
        }

        private var playbackOptionButtons: some View {
            GlassEffectContainer(spacing: PrismediaSpacing.large) {
                HStack(spacing: PrismediaSpacing.large) {
                    playbackOptionButton(
                        menu: .audio,
                        focusTarget: .audio,
                        systemImage: "waveform"
                    )
                    playbackOptionButton(
                        menu: .subtitles,
                        focusTarget: .subtitles,
                        systemImage: "captions.bubble"
                    )
                    playbackOptionButton(
                        menu: .speed,
                        focusTarget: .speed,
                        systemImage: "speedometer"
                    )
                }
            }
            .prismediaFocusSection()
        }

        private func playbackOptionButton(
            menu: TVPlaybackOptionsMenu,
            focusTarget: TVCompatibilityPlayerFocusTarget,
            systemImage: String
        ) -> some View {
            Button {
                openOptionsMenu(menu)
            } label: {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .frame(width: 30, height: 30)
                    .padding(PrismediaSpacing.small)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .focused($focusedControl, equals: focusTarget)
            .accessibilityLabel(menu.title)
            .accessibilityIdentifier(menu.title)
            .onMoveCommand { direction in
                handlePlaybackOptionsMove(from: focusTarget, direction: direction)
            }
        }

        @ViewBuilder
        private var optionsMenuActions: some View {
            switch activeOptionsMenu {
            case .audio:
                if controller.audioChoices.isEmpty {
                    Button("Default") {}
                        .disabled(true)
                } else {
                    ForEach(controller.audioChoices) { choice in
                        optionChoice(
                            choice.title,
                            selected: controller.selectedAudioChoiceID == choice.id
                        ) {
                            Task { await controller.selectAudio(id: choice.id) }
                        }
                    }
                }
            case .subtitles:
                if controller.subtitleChoices.isEmpty {
                    Button("No Subtitles Available") {}
                        .disabled(true)
                } else {
                    ForEach(controller.subtitleChoices) { choice in
                        optionChoice(
                            choice.title,
                            selected: controller.selectedSubtitleChoiceID == choice.id
                        ) {
                            Task { await controller.selectSubtitle(id: choice.id) }
                        }
                    }
                }
            case .speed:
                ForEach(VideoPlaybackSettings.availableRates, id: \.self) { rate in
                    optionChoice(
                        VideoPlaybackSettings.label(for: rate),
                        selected: controller.playbackRate == rate
                    ) {
                        controller.setPlaybackRate(rate)
                    }
                }
            case nil:
                EmptyView()
            }
        }

        private func optionChoice(
            _ title: String,
            selected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button {
                action()
                dismissOptionsMenu()
            } label: {
                if selected {
                    Label(title, systemImage: "checkmark")
                } else {
                    Text(title)
                }
            }
        }

        private var optionsMenuPresented: Binding<Bool> {
            Binding(
                get: { activeOptionsMenu != nil },
                set: { isPresented in
                    if !isPresented { dismissOptionsMenu() }
                }
            )
        }

        private var displayedTime: Double {
            previewTime ?? controller.currentTime
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
            controller.isPlaying
                && focusedControl == .timeline
                && activeOptionsMenu == nil
                && !isSeeking
        }

        private var controlsAutoDismissDelay: Duration {
            #if DEBUG
                PrismediaUITestBootstrap.videoControlsAutoHideDelay() ?? .seconds(15)
            #else
                .seconds(15)
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

        private func moveToPlaybackOptions() {
            revealControls()
            moveFocus(to: .audio)
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
            if let target { moveFocus(to: target) }
            revealControls()
        }

        private func handleTimelineFocusChange(_ isFocused: Bool) {
            Task { @MainActor in
                if isFocused {
                    focusedControl = .timeline
                    revealControls()
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
            controller.togglePlayback()
        }

        private func handleExitCommand() {
            if isScrubbing || scanSide != nil {
                cancelSeekPreview()
                revealControls()
            } else if activeOptionsMenu != nil {
                dismissOptionsMenu()
            } else {
                onRequestDismiss()
            }
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
                if finished, resumePlayback { controller.play() }
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
                if finished, resumePlayback { controller.play() }
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

        private func boundedTime(_ time: Double) -> Double {
            max(0, min(time, controller.duration > 0 ? controller.duration : time))
        }

        private func openOptionsMenu(_ menu: TVPlaybackOptionsMenu) {
            activeOptionsMenu = menu
            revealControls()
        }

        private func dismissOptionsMenu() {
            guard let menu = activeOptionsMenu else { return }
            activeOptionsMenu = nil
            revealControls()
            moveFocus(to: focusTarget(for: menu))
        }

        private func focusTarget(for menu: TVPlaybackOptionsMenu) -> TVCompatibilityPlayerFocusTarget {
            switch menu {
            case .audio: .audio
            case .subtitles: .subtitles
            case .speed: .speed
            }
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
