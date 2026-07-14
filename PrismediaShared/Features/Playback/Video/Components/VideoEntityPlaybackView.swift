import SwiftUI

struct VideoEntityPlaybackView: View {
    let detail: EntityDetail
    let ownerLink: EntityLink
    let detailLoader: any EntityDetailLoading
    let playbackService: any VideoPlaybackServicing
    let preparation: VideoPlaybackPreparationCoordinator
    let presentationMode: VideoPlaybackPresentationMode
    let tvLayout: TVVideoPlaybackLayout
    let presentsFullscreenOnTV: Bool
    let onFullscreenDismiss: () -> Void
    let onAdvance: (EntityLink) -> Void

    init(
        detail: EntityDetail,
        ownerLink: EntityLink,
        detailLoader: any EntityDetailLoading,
        playbackService: any VideoPlaybackServicing,
        preparation: VideoPlaybackPreparationCoordinator,
        presentationMode: VideoPlaybackPresentationMode = .inline,
        tvLayout: TVVideoPlaybackLayout = .standard,
        presentsFullscreenOnTV: Bool = false,
        onFullscreenDismiss: @escaping () -> Void = {},
        onAdvance: @escaping (EntityLink) -> Void
    ) {
        self.detail = detail
        self.ownerLink = ownerLink
        self.detailLoader = detailLoader
        self.playbackService = playbackService
        self.preparation = preparation
        self.presentationMode = presentationMode
        self.tvLayout = tvLayout
        self.presentsFullscreenOnTV = presentsFullscreenOnTV
        self.onFullscreenDismiss = onFullscreenDismiss
        self.onAdvance = onAdvance
    }

    @Environment(\.videoPlaybackSession) private var playbackSession
    @State private var videoDetail: EntityDetail?
    @State private var playbackController: VideoPlaybackController?
    @State private var loadFailed = false
    #if os(tvOS)
        @State private var tvFullscreenPresentation: TVFullscreenPlaybackPresentation?
    #endif
    @State private var isAdvancingPlayback = false
    @State private var isFullscreenPresented = false
    @State private var advanceNavigation = VideoPlaybackAdvanceNavigation()

    var body: some View {
        #if os(tvOS)
            tvBody
        #else
            Group {
                if presentationMode == .fullscreenOnly {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                        .modifier(
                            VideoFullscreenPresentationModifier(
                                isPresented: $isFullscreenPresented,
                                controller: presentedPlaybackController,
                                title: presentedVideoDetail?.title ?? playbackTitle,
                                isInteractive: fullscreenPlayerIsInteractive,
                                playRequested: preparation.playRequested,
                                onPlay: startPlayback
                            )
                        )
                        .onChange(of: isFullscreenPresented) { _, isPresented in
                            fullscreenPresentationDidChange(isPresented)
                        }
                } else if preparation.phase == .ready,
                    let videoDetail = presentedVideoDetail,
                    let playbackController = presentedPlaybackController
                {
                    ResolvedVideoPlaybackView(
                        detail: videoDetail,
                        service: playbackService,
                        controller: playbackController,
                        presentationMode: presentationMode,
                        onFullscreenChange: fullscreenPresentationDidChange
                    )
                } else {
                    VideoPlaybackPosterView(
                        detail: detail,
                        ownerLink: ownerLink,
                        phase: preparation.phase,
                        onPlay: startPlayback
                    )
                }
            }
            .task(id: detail.id) {
                preparation.restoreActivePlaybackIfNeeded(
                    session: playbackSession,
                    ownerLink: ownerLink,
                    onPlaybackCompleted: playbackDidComplete
                )
                if presentationMode == .fullscreenOnly {
                    isFullscreenPresented = true
                }
                #if DEBUG
                    if PrismediaUITestBootstrap.startsVideoAutomatically() {
                        startPlayback()
                    } else if VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                        for: ownerLink.intent
                    ) {
                        warmPlayback()
                    }
                #else
                    if VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(for: ownerLink.intent) {
                        warmPlayback()
                    }
                #endif
            }
            .onChange(of: preparation.phase) {
                guard preparation.phase == .idle else { return }
                videoDetail = nil
                playbackController = nil
            }
            .alert("Couldn’t Play Video", isPresented: fullscreenPreparationErrorPresented) {
                Button("Try Again") { warmPlayback() }
                Button("Cancel", role: .cancel) { preparation.reset() }
            } message: {
                Text(fullscreenPreparationErrorMessage ?? "Please try again.")
            }
        #endif
    }

    #if os(tvOS)
        private var tvBody: some View {
            Group {
                if let videoDetail {
                    let options = TVPlaybackOptions(resumeSeconds: initialResumeSeconds(in: videoDetail))
                    HStack(spacing: PrismediaSpacing.section) {
                        ForEach(Array(options.actions.enumerated()), id: \.offset) { _, action in
                            Button {
                                startTVPlayback(videoDetail, action: action)
                            } label: {
                                Label(
                                    label(for: action, resumeSeconds: options.resumeSeconds),
                                    systemImage: systemImage(for: action)
                                )
                                .font(
                                    tvLayout == .compact
                                        ? .system(size: 20, weight: .semibold)
                                        : .title3.bold()
                                )
                                .padding(.horizontal, tvLayout == .compact ? 12 : 24)
                                .frame(
                                    minWidth: tvLayout == .compact ? 160 : 300,
                                    minHeight: tvLayout == .compact ? 44 : 72
                                )
                            }
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.glass(.clear))
                            .controlSize(tvLayout == .compact ? .small : .regular)
                            .accessibilityIdentifier(identifier(for: action))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 72)
                    .padding(.vertical, tvLayout == .compact ? 6 : 14)
                    .prismediaFocusSection()
                } else if loadFailed {
                    ContentUnavailableView("Video Unavailable", systemImage: "exclamationmark.triangle")
                } else {
                    ProgressView("Preparing playback options…")
                }
            }
            .task(id: detail.id) {
                await resolveVideo()
                guard presentsFullscreenOnTV, let videoDetail else { return }
                let action = TVPlaybackOptions(
                    resumeSeconds: initialResumeSeconds(in: videoDetail)
                ).automaticAction
                startTVPlayback(videoDetail, action: action)
            }
            .fullScreenCover(
                item: $tvFullscreenPresentation,
                onDismiss: finishTVFullscreenPlayback
            ) { presentation in
                let controller = presentation.controller
                TVFullscreenPlayerSurface(
                    controller: controller,
                    onRequestDismiss: { tvFullscreenPresentation = nil }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            .accessibilityIdentifier("video-detail.playback-actions")
        }

        private func startTVPlayback(_ resolved: EntityDetail, action: TVPlaybackAction) {
            // Enter fullscreen and begin warming immediately. Production playback
            // remains paused until the user presses Play; automated validation can
            // opt into playback once the item is ready.
            #if DEBUG
                let autoPlay = PrismediaUITestBootstrap.startsVideoAutomatically()
                let resumeAt = PrismediaUITestBootstrap.videoResumeSeconds() ?? action.startSeconds
            #else
                let autoPlay = false
                let resumeAt = action.startSeconds
            #endif
            prepareController(
                for: resolved,
                resumeAt: resumeAt,
                autoPlay: autoPlay
            )
            guard let playbackController else { return }
            isFullscreenPresented = true
            tvFullscreenPresentation = TVFullscreenPlaybackPresentation(
                controller: playbackController
            )
        }

        private func stopTVPlayback() {
            playbackSession?.reset()
            playbackController?.stop()
            playbackController = nil
        }

        private func finishTVFullscreenPlayback() {
            isFullscreenPresented = false
            stopTVPlayback()
            _ = advanceNavigation.fullscreenDidDismiss()
        }

        private func label(for action: TVPlaybackAction, resumeSeconds: Double) -> String {
            switch action {
            case .resume: "Resume \(playbackTimestamp(resumeSeconds))"
            case .play: "Play"
            case .playFromBeginning: "Play from Beginning"
            }
        }

        private func playbackTimestamp(_ seconds: Double) -> String {
            let total = max(0, Int(seconds.rounded(.down)))
            let hours = total / 3_600
            let minutes = (total % 3_600) / 60
            let remainingSeconds = total % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
            }
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }

        private func systemImage(for action: TVPlaybackAction) -> String {
            switch action {
            case .resume: "play.fill"
            case .play: "play.fill"
            case .playFromBeginning: "arrow.counterclockwise"
            }
        }

        private func identifier(for action: TVPlaybackAction) -> String {
            switch action {
            case .resume: "video-detail.resume"
            case .play: "video-detail.play"
            case .playFromBeginning: "video-detail.play-from-beginning"
            }
        }
    #endif

    #if os(tvOS)
        private func resolveVideo() async {
            do {
                videoDetail = try await VideoEntityPlaybackStartup.resolve(
                    detail: detail,
                    sourceThumbnail: ownerLink.sourceThumbnail,
                    detailLoader: detailLoader
                )
            } catch is CancellationError {
                return
            } catch {
                loadFailed = true
            }
        }
    #endif

    #if !os(tvOS)
        private func startPlayback() {
            warmPlayback()
            preparation.requestPlayback()
        }

        private func warmPlayback() {
            preparation.start(
                VideoPlaybackPreparationRequest(
                    detail: detail,
                    ownerLink: ownerLink,
                    detailLoader: detailLoader,
                    playbackService: playbackService,
                    session: playbackSession,
                    onPlaybackCompleted: playbackDidComplete
                ))
        }

        private var playbackTitle: String {
            ownerLink.thumbnailPreview?.title ?? detail.title
        }

        private var fullscreenPlayerIsInteractive: Bool {
            guard let controller = presentedPlaybackController else { return false }
            return controller.isReadyToPlay
        }

        private var presentedVideoDetail: EntityDetail? {
            videoDetail ?? preparation.videoDetail
        }

        private var presentedPlaybackController: VideoPlaybackController? {
            playbackController ?? preparation.controller
        }
    #endif

    #if os(tvOS)
        private var presentedVideoDetail: EntityDetail? { videoDetail }
        private var presentedPlaybackController: VideoPlaybackController? { playbackController }
    #endif

    private func playbackDidComplete(_ resolvedID: UUID) {
        let lifecycle = preparation.lifecycleToken()
        Task {
            await advancePlayback(after: resolvedID, lifecycle: lifecycle)
        }
    }

    private func prepareController(
        for resolved: EntityDetail,
        resumeAt: Double,
        autoPlay: Bool = false,
        restoreLink: EntityLink? = nil,
        activationOwnerLink: EntityLink? = nil
    ) {
        let controller: VideoPlaybackController
        if let playbackSession {
            controller = playbackSession.activate(
                ownerLink: activationOwnerLink ?? ownerLink,
                restoreLink: restoreLink,
                videoDetail: resolved,
                nowPlayingDetail: activationOwnerLink == nil ? detail : nil,
                resumeAt: resumeAt,
                autoPlay: autoPlay
            )
        } else {
            let subtitles =
                resolved.capabilities.compactMap { capability -> [EntitySubtitle]? in
                    guard case .subtitles(let subtitles) = capability else { return nil }
                    return subtitles.items
                }.first ?? []
            controller = VideoPlaybackController(
                videoID: resolved.id,
                service: playbackService,
                sidecarSubtitles: subtitles
            )
            Task {
                await controller.load(resumeAt: resumeAt)
                guard !Task.isCancelled, autoPlay else { return }
                controller.play()
            }
        }
        controller.onPlaybackCompleted = { [resolvedID = resolved.id] in
            playbackDidComplete(resolvedID)
        }
        adoptPlaybackController(controller)
    }

    private func advancePlayback(
        after completedVideoID: UUID,
        lifecycle: VideoPlaybackLifecycleToken
    ) async {
        guard !isAdvancingPlayback,
            preparation.isCurrent(lifecycle),
            let completedDetail = presentedVideoDetail,
            completedDetail.id == completedVideoID
        else { return }

        isAdvancingPlayback = true
        defer { isAdvancingPlayback = false }

        let resolver = VideoPlaybackAdvanceResolver(loader: detailLoader)
        guard
            let resolution = await resolver.resolveNext(
                after: completedDetail,
                lifecycleIsCurrent: { preparation.isCurrent(lifecycle) }
            ), preparation.isCurrent(lifecycle)
        else { return }

        videoDetail = resolution.detail
        let playbackOwnerLink = advancedPlaybackOwnerLink(for: resolution.link)
        advanceController(to: resolution.detail, link: playbackOwnerLink)
        if let destination = advanceNavigation.receive(
            resolution.link,
            isFullscreen: isFullscreenPresented
        ) {
            onAdvance(destination)
        }
    }

    private func advancedPlaybackOwnerLink(for successorLink: EntityLink) -> EntityLink {
        guard ownerLink.kind == .videoSeason,
            let successor = successorLink.sourceThumbnail
        else { return successorLink }
        return EntityLink(thumbnail: successor, intent: .playback)
    }

    private func fullscreenPresentationDidChange(_ isPresented: Bool) {
        isFullscreenPresented = isPresented
        guard !isPresented else { return }
        let advancedWhileFullscreen = advanceNavigation.fullscreenDidDismiss()
        guard presentationMode == .fullscreenOnly || advancedWhileFullscreen else { return }
        presentedPlaybackController?.stop()
        playbackSession?.reset()
        preparation.reset()
        videoDetail = nil
        playbackController = nil
        onFullscreenDismiss()
    }

    #if !os(tvOS)
        private var fullscreenPreparationErrorMessage: String? {
            guard presentationMode == .fullscreenOnly,
                case .failure(let message) = preparation.phase
            else { return nil }
            return message
        }

        private var fullscreenPreparationErrorPresented: Binding<Bool> {
            Binding(
                get: { fullscreenPreparationErrorMessage != nil },
                set: { _ in }
            )
        }
    #endif

    private func advanceController(to detail: EntityDetail, link: EntityLink) {
        if let currentController = presentedPlaybackController,
            let controller = playbackSession?.advance(
                from: currentController,
                to: link,
                videoDetail: detail
            )
        {
            controller.onPlaybackCompleted = { [resolvedID = detail.id] in
                playbackDidComplete(resolvedID)
            }
            adoptPlaybackController(controller)
            return
        }

        prepareController(
            for: detail,
            resumeAt: 0,
            autoPlay: true,
            restoreLink: link,
            activationOwnerLink: link
        )
    }

    private func resumeSeconds(in detail: EntityDetail) -> Double? {
        detail.capabilities.compactMap { capability -> Double? in
            guard case .playback(let playback) = capability else { return nil }
            return playback.resumeSeconds
        }.first
    }

    private func adoptPlaybackController(_ controller: VideoPlaybackController) {
        playbackController = controller
        #if os(tvOS)
            tvFullscreenPresentation?.updateController(controller)
        #endif
    }

    private func initialResumeSeconds(in detail: EntityDetail) -> Double {
        VideoInitialResumePosition.resolve(
            detailResumeSeconds: resumeSeconds(in: detail),
            thumbnailResumeSeconds: ownerLink.thumbnailPreview?.resumeSeconds
        )
    }
}

#if !os(tvOS)
    #if DEBUG
        #Preview("Video Player · Native") {
            @Previewable @State var preparation = VideoPlaybackPreparationCoordinator()
            let json = """
                {"id":"11111111-1111-1111-1111-111111111111","kind":"video","title":"Signal in the Static","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
                """
            let detail = try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
            PreviewShell {
                VideoEntityPlaybackView(
                    detail: detail,
                    ownerLink: EntityLink(entityID: detail.id, kind: detail.kind),
                    detailLoader: VideoPlaybackPreviewLoader(detail: detail),
                    playbackService: VideoPlaybackPreviewService(),
                    preparation: preparation,
                    onAdvance: { _ in }
                )
                .background(Color.black)
            }
        }

        #if !os(tvOS)
            #Preview("Video Player · Deferred States") {
                let json = """
                    {"id":"11111111-1111-1111-1111-111111111111","kind":"video","title":"Signal in the Static","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
                    """
                let detail = try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
                let owner = EntityLink(entityID: detail.id, kind: detail.kind)
                PreviewShell {
                    ScrollView {
                        VStack(spacing: PrismediaSpacing.extraLarge) {
                            VideoPlaybackPosterView(
                                detail: detail,
                                ownerLink: owner,
                                phase: .idle,
                                onPlay: {}
                            )
                            VideoPlaybackPosterView(
                                detail: detail,
                                ownerLink: owner,
                                phase: .loading,
                                onPlay: {}
                            )
                            VideoPlaybackPosterView(
                                detail: detail,
                                ownerLink: owner,
                                phase: .failure("The server could not prepare this video."),
                                onPlay: {}
                            )
                        }
                        .padding()
                    }
                    .background(PrismediaBackdrop())
                }
            }
        #endif
    #endif
#endif
