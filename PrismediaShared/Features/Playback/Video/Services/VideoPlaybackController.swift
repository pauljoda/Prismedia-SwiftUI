@preconcurrency import AVFoundation
import Combine
import Foundation
import Observation

@Observable
@MainActor
public final class VideoPlaybackController {
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0
    public private(set) var delivery: VideoPlaybackDelivery?
    public private(set) var errorMessage: String?
    public private(set) var isLoading = false
    public private(set) var isReadyToPlay = false
    public private(set) var isPlaying = false
    public private(set) var isWaiting = false
    public private(set) var bufferedRanges: [CMTimeRange] = []
    public private(set) var badges: [VideoPlaybackBadge] = []
    public private(set) var audioChoices: [VideoMediaSelectionChoice] = []
    public private(set) var subtitleChoices: [VideoMediaSelectionChoice] = []
    public private(set) var selectedAudioChoiceID: String?
    public private(set) var selectedSubtitleChoiceID = "off"
    public private(set) var playbackRate: Float = 1
    public private(set) var arePlaybackOptionsReady = false
    private(set) var shuttleSide: VideoPlayerGestureSide?
    private(set) var activeSubtitleContent: VideoSubtitleText?
    public var activeSubtitleText: String? { activeSubtitleContent?.plainText }
    public private(set) var activeAssSubtitleContents: String?
    public private(set) var subtitleAppearance: VideoSubtitleAppearance = .default
    private(set) var videoScalingMode: VideoScalingMode = .fit

    @ObservationIgnored var onPlaybackCompleted: (() -> Void)?

    public let player = AVPlayer()
    let pictureInPicture = VideoPictureInPictureCoordinator()

    private let videoID: UUID
    private let service: any VideoPlaybackServicing
    private let audioSession: any VideoAudioSessionPreparing
    private let sidecarSubtitles: [EntitySubtitle]
    private let playbackReporter: VideoPlaybackReporter
    @ObservationIgnored private var statusObservation: AnyCancellable?
    @ObservationIgnored private var playbackFailureObservation: AnyCancellable?
    @ObservationIgnored private var playbackCompletionObservation: AnyCancellable?
    @ObservationIgnored private var bufferObservation: AnyCancellable?
    @ObservationIgnored private var playerStateObservation: AnyCancellable?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var usedSafeFallback = false
    @ObservationIgnored private var audioSelectionGroup: AVMediaSelectionGroup?
    @ObservationIgnored private var subtitleSelectionGroup: AVMediaSelectionGroup?
    @ObservationIgnored private var audioOptionsByID: [String: AVMediaSelectionOption] = [:]
    @ObservationIgnored private var subtitleOptionsByID: [String: AVMediaSelectionOption] = [:]
    @ObservationIgnored private var serverAudioIndexByID: [String: Int] = [:]
    @ObservationIgnored private var shuttleTask: Task<Void, Never>?
    @ObservationIgnored private var mediaSelectionTask: Task<Void, Never>?
    @ObservationIgnored private var resumeAfterShuttle = false
    @ObservationIgnored private var sidecarSubtitleByID: [String: EntitySubtitle] = [:]
    @ObservationIgnored private var activeSubtitleCues: [VideoSubtitleCue] = []
    @ObservationIgnored private var pendingInitialResumeSeconds: Double?
    @ObservationIgnored private var subtitleSettings: VideoSubtitleSettings = .default
    @ObservationIgnored private var hasExplicitSubtitleSelection = false
    #if os(tvOS)
        @ObservationIgnored private var tvSubtitleSelectionTask: Task<Void, Never>?
        @ObservationIgnored private var tvSubtitleSelectionGeneration = 0
    #endif

    public init(
        videoID: UUID,
        service: any VideoPlaybackServicing,
        sidecarSubtitles: [EntitySubtitle] = []
    ) {
        self.videoID = videoID
        self.service = service
        self.sidecarSubtitles = sidecarSubtitles
        audioSession = SystemVideoAudioSession()
        playbackReporter = VideoPlaybackReporter(
            service: service as? any VideoPlaybackReporting
        )
        configureSidecarChoices()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in self?.observe(time: time) }
        }
        observePlayerState()
    }

    init(
        videoID: UUID,
        service: any VideoPlaybackServicing,
        audioSession: any VideoAudioSessionPreparing,
        sidecarSubtitles: [EntitySubtitle] = []
    ) {
        self.videoID = videoID
        self.service = service
        self.audioSession = audioSession
        self.sidecarSubtitles = sidecarSubtitles
        playbackReporter = VideoPlaybackReporter(
            service: service as? any VideoPlaybackReporting
        )
        configureSidecarChoices()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in self?.observe(time: time) }
        }
        observePlayerState()
    }

    isolated deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }

    public func load(resumeAt: Double = 0) async {
        guard player.currentItem == nil, !isLoading else { return }
        usedSafeFallback = false
        hasExplicitSubtitleSelection = false
        isLoading = true
        defer { isLoading = false }
        async let audioSessionReady: Void = prepareAudioSession()
        async let loadedSubtitleSettings = try? service.videoSubtitleSettings()
        do {
            let plan = try await service.negotiateVideoPlayback(videoID: videoID, forceTranscode: false)
            await audioSessionReady
            let subtitleSettings = await loadedSubtitleSettings ?? .default
            self.subtitleSettings = subtitleSettings
            subtitleAppearance = subtitleSettings.appearance
            install(plan, resumeAt: resumeAt)
            #if os(tvOS)
                scheduleTVSubtitleDefaults(subtitleSettings)
            #else
                await applySubtitleDefaults(subtitleSettings)
            #endif
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareAudioSession() async {
        do {
            try await audioSession.prepare()
        } catch {
            #if DEBUG
                print("Video audio session activation failed: \(error)")
            #endif
        }
    }

    public func seek(to seconds: Double) {
        seek(to: seconds) { _ in }
    }

    public func seek(
        to seconds: Double,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        let target = max(0, min(seconds, duration > 0 ? duration : seconds))
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { finished in
            Task { @MainActor in
                if finished { self.playbackReporter.didSeek(positionSeconds: target) }
                completion(finished)
            }
        }
        currentTime = target
    }

    public func togglePlayback() {
        guard isReadyToPlay else { return }
        if player.timeControlStatus == .playing
            || player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            || player.rate != 0
        {
            player.pause()
        } else {
            player.playImmediately(atRate: playbackRate)
        }
    }

    func play() {
        player.playImmediately(atRate: playbackRate)
    }

    func pause() {
        player.pause()
    }

    public func skip(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    public func setPlaybackRate(_ rate: Float) {
        guard VideoPlaybackSettings.availableRates.contains(rate) else { return }
        playbackRate = rate
        if isPlaying || isWaiting { player.playImmediately(atRate: rate) }
    }

    func setVideoScalingMode(_ mode: VideoScalingMode) {
        videoScalingMode = mode
    }

    public func selectAudio(id: String) async {
        if let group = audioSelectionGroup, let option = audioOptionsByID[id] {
            player.currentItem?.select(option, in: group)
            selectedAudioChoiceID = id
            return
        }
        guard let streamIndex = serverAudioIndexByID[id] else { return }
        let resumeAt = currentTime
        let shouldResume = isPlaying || isWaiting
        do {
            let plan = try await service.negotiateVideoPlayback(
                videoID: videoID,
                forceTranscode: false,
                audioStreamIndex: streamIndex
            )
            install(plan, resumeAt: resumeAt)
            selectedAudioChoiceID = id
            if shouldResume { player.playImmediately(atRate: playbackRate) }
        } catch {
            errorMessage = "The selected audio track could not be loaded."
        }
    }

    public func selectSubtitle(id: String) async {
        #if os(tvOS)
            tvSubtitleSelectionTask?.cancel()
            tvSubtitleSelectionTask = nil
            tvSubtitleSelectionGeneration += 1
            await selectSubtitle(
                id: id,
                isExplicit: true,
                tvGeneration: tvSubtitleSelectionGeneration
            )
        #else
            await selectSubtitle(id: id, isExplicit: true)
        #endif
    }

    private func selectSubtitle(
        id: String,
        isExplicit: Bool,
        tvGeneration: Int? = nil
    ) async {
        if isExplicit { hasExplicitSubtitleSelection = true }
        if id == "off" || subtitleOptionsByID[id] != nil {
            if let group = subtitleSelectionGroup {
                player.currentItem?.select(subtitleOptionsByID[id], in: group)
            }
            activeSubtitleCues = []
            activeSubtitleContent = nil
            activeAssSubtitleContents = nil
            selectedSubtitleChoiceID = id
            return
        }
        guard let sidecar = sidecarSubtitleByID[id] else { return }
        if let group = subtitleSelectionGroup { player.currentItem?.select(nil, in: group) }
        guard
            let encodedID = sidecar.id.addingPercentEncoding(
                withAllowedCharacters: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
            )
        else { return }
        do {
            let usesPreservedSource = VideoSidecarSubtitlePolicy.usesPreservedSource(
                sourceFormat: sidecar.sourceFormat,
                supportsAssRenderer: Self.supportsAssRenderer
            )
            let sourceSuffix = usesPreservedSource ? "/source" : ""
            let data = try await service.mediaData(
                for: "/api/videos/\(videoID.uuidString.lowercased())/subtitles/\(encodedID)\(sourceSuffix)"
            )
            guard let contents = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            guard isCurrentTVSubtitleSelection(tvGeneration) else { return }
            selectedSubtitleChoiceID = id
            if usesPreservedSource {
                activeSubtitleCues = []
                activeSubtitleContent = nil
                activeAssSubtitleContents = contents
            } else {
                #if os(tvOS)
                    let cues = try await Task.detached(priority: .userInitiated) {
                        try WebVTTSubtitleParser.parse(contents)
                    }.value
                #else
                    let cues = try WebVTTSubtitleParser.parse(contents)
                #endif
                guard isCurrentTVSubtitleSelection(tvGeneration) else { return }
                activeAssSubtitleContents = nil
                activeSubtitleCues = cues
                activeSubtitleContent = WebVTTSubtitleParser.activeContent(
                    at: currentTime,
                    cues: activeSubtitleCues
                )
            }
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentTVSubtitleSelection(tvGeneration) else { return }
            errorMessage = "The selected subtitle track could not be loaded."
        }
    }

    public func startPictureInPicture() { pictureInPicture.start() }
    public func stopPictureInPicture() { pictureInPicture.stop() }
    func attachPictureInPicture(to layer: AVPlayerLayer) { pictureInPicture.attach(to: layer) }
    func detachPictureInPicture(from layer: AVPlayerLayer) { pictureInPicture.detach(from: layer) }

    func beginShuttle(on side: VideoPlayerGestureSide) {
        guard isReadyToPlay, shuttleSide == nil else { return }
        resumeAfterShuttle = isPlaying || isWaiting
        shuttleSide = side
        if side == .right {
            player.playImmediately(atRate: 2)
            return
        }
        if player.currentItem?.canPlayFastReverse == true {
            player.rate = -2
            return
        }
        player.pause()
        shuttleTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.seekForShuttle(to: self.currentTime - 0.2)
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    public func endShuttle() {
        guard shuttleSide != nil else { return }
        shuttleTask?.cancel()
        shuttleTask = nil
        player.pause()
        shuttleSide = nil
        if resumeAfterShuttle { player.playImmediately(atRate: playbackRate) }
        resumeAfterShuttle = false
        playbackReporter.didSeek(positionSeconds: currentTime)
    }

    private func seekForShuttle(to seconds: Double) {
        let target = max(0, min(seconds, duration > 0 ? duration : seconds))
        let tolerance = CMTime(seconds: 0.08, preferredTimescale: 600)
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: tolerance,
            toleranceAfter: tolerance
        )
        currentTime = target
    }

    public func dismissError() {
        errorMessage = nil
    }

    /// Clears an installed failed item before beginning a fresh negotiation.
    /// `load` intentionally no-ops while any current item is installed, so an
    /// explicit retry must first return the controller to its unloaded state.
    func retryLoad(resumeAt: Double) async {
        stop()
        errorMessage = nil
        await load(resumeAt: resumeAt)
    }

    public func stop() {
        endShuttle()
        playbackReporter.stop(positionSeconds: currentTime)
        player.pause()
        player.replaceCurrentItem(with: nil)
        mediaSelectionTask?.cancel()
        mediaSelectionTask = nil
        #if os(tvOS)
            tvSubtitleSelectionTask?.cancel()
            tvSubtitleSelectionTask = nil
            tvSubtitleSelectionGeneration += 1
        #endif
        statusObservation = nil
        playbackFailureObservation = nil
        playbackCompletionObservation = nil
        bufferObservation = nil
        isReadyToPlay = false
        isPlaying = false
        isWaiting = false
        bufferedRanges = []
        audioChoices = []
        configureSidecarChoices()
        audioSelectionGroup = nil
        subtitleSelectionGroup = nil
        audioOptionsByID = [:]
        subtitleOptionsByID = [:]
        activeSubtitleCues = []
        activeSubtitleContent = nil
        activeAssSubtitleContents = nil
        subtitleSettings = .default
        hasExplicitSubtitleSelection = false
        arePlaybackOptionsReady = false
    }

    private func install(_ plan: VideoPlaybackPlan, resumeAt: Double) {
        playbackReporter.install(plan: plan, positionSeconds: resumeAt)
        // HLS child playlists and segments do not inherit the query string from
        // the master playlist URL. Supplying the bearer header on AVURLAsset
        // keeps every request in the native playback chain authenticated.
        let asset = AVURLAsset(
            url: plan.url,
            options: plan.httpHeaders.isEmpty
                ? nil
                : ["AVURLAssetHTTPHeaderFieldsKey": plan.httpHeaders]
        )
        let item = AVPlayerItem(asset: asset)
        audioSelectionGroup = nil
        subtitleSelectionGroup = nil
        audioOptionsByID = [:]
        subtitleOptionsByID = [:]
        configureSidecarChoices()
        delivery = plan.delivery
        badges = plan.badges
        serverAudioIndexByID = Dictionary(
            uniqueKeysWithValues: plan.audioStreams.map {
                ("server-audio-\($0.index)", $0.index)
            })
        audioChoices = plan.audioStreams.map {
            .init(id: "server-audio-\($0.index)", title: $0.title)
        }
        selectedAudioChoiceID =
            plan.audioStreams.first(where: \.isSelected).map {
                "server-audio-\($0.index)"
            } ?? audioChoices.first?.id
        duration = plan.durationSeconds
        isReadyToPlay = false
        pendingInitialResumeSeconds = resumeAt > 0 ? resumeAt : nil
        arePlaybackOptionsReady = false
        bufferedRanges = []
        errorMessage = nil
        observeStatus(of: item)
        player.replaceCurrentItem(with: item)
        mediaSelectionTask?.cancel()
        mediaSelectionTask = Task { [weak self, weak item] in
            guard let self, let item else { return }
            await self.loadMediaSelectionOptions(for: item)
        }
    }

    private func observeStatus(of item: AVPlayerItem) {
        statusObservation = item.publisher(for: \.status)
            .sink { [weak self, weak item] status in
                guard let self else { return }
                Task { @MainActor in
                    if status == .readyToPlay {
                        self.applyPendingInitialResumeIfNeeded(for: item)
                    } else if status == .failed, let item {
                        await self.recover(from: item.error)
                    }
                }
            }
        bufferObservation = item.publisher(for: \.loadedTimeRanges)
            .sink { [weak self] values in
                let ranges = values.compactMap { $0.timeRangeValue }
                Task { @MainActor in self?.bufferedRanges = ranges }
            }
        playbackFailureObservation = NotificationCenter.default.publisher(
            for: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
        .sink { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            Task { @MainActor in await self?.recover(from: error) }
        }
        playbackCompletionObservation = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        .sink { [weak self, weak item] _ in
            Task { @MainActor in
                guard let self, item === self.player.currentItem else { return }
                self.playbackReporter.complete()
                self.onPlaybackCompleted?()
            }
        }
    }

    private func applyPendingInitialResumeIfNeeded(for item: AVPlayerItem?) {
        guard item === player.currentItem else { return }
        guard let resumeSeconds = pendingInitialResumeSeconds else {
            isReadyToPlay = true
            return
        }
        pendingInitialResumeSeconds = nil
        let target = CMTime(seconds: resumeSeconds, preferredTimescale: 600)
        let tolerance = CMTime(seconds: 1, preferredTimescale: 600)
        player.seek(
            to: target,
            toleranceBefore: tolerance,
            toleranceAfter: tolerance
        ) { [weak self, weak item] finished in
            Task { @MainActor in
                guard let self, finished, item === self.player.currentItem else { return }
                self.currentTime = resumeSeconds
                self.isReadyToPlay = true
            }
        }
    }

    private func observePlayerState() {
        playerStateObservation = player.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                Task { @MainActor in
                    guard let self else { return }
                    self.isPlaying = status == .playing
                    self.isWaiting = status == .waitingToPlayAtSpecifiedRate
                    if self.isPlaying {
                        self.playbackReporter.playbackStarted(positionSeconds: self.currentTime)
                    }
                }
            }
    }

    private func loadMediaSelectionOptions(for item: AVPlayerItem) async {
        async let audioGroup = try? item.asset.loadMediaSelectionGroup(for: .audible)
        async let subtitleGroup = try? item.asset.loadMediaSelectionGroup(for: .legible)
        let groups = await (audioGroup, subtitleGroup)
        guard !Task.isCancelled, item === player.currentItem else { return }
        if let audio = groups.0 { installAudioOptions(audio, item: item) }
        if let subtitles = groups.1 { installSubtitleOptions(subtitles, item: item) }
        arePlaybackOptionsReady = true
    }

    private func installAudioOptions(_ group: AVMediaSelectionGroup, item: AVPlayerItem) {
        let pairs = group.options.enumerated().map { index, option in ("audio-\(index)", option) }
        guard pairs.count > 1 || audioChoices.isEmpty else { return }
        audioSelectionGroup = group
        audioOptionsByID = Dictionary(uniqueKeysWithValues: pairs)
        audioChoices = pairs.map { .init(id: $0.0, title: $0.1.displayName) }
        let selected = item.currentMediaSelection.selectedMediaOption(in: group)
        selectedAudioChoiceID = pairs.first(where: { $0.1 == selected })?.0 ?? pairs.first?.0
    }

    private func installSubtitleOptions(_ group: AVMediaSelectionGroup, item: AVPlayerItem) {
        let pairs = group.options.enumerated().map { index, option in ("subtitle-\(index)", option) }
        subtitleSelectionGroup = group
        subtitleOptionsByID = Dictionary(uniqueKeysWithValues: pairs)
        subtitleChoices =
            baseSidecarSubtitleChoices
            + pairs.map {
                .init(id: $0.0, title: $0.1.displayName)
            }
        guard !selectedSubtitleChoiceID.hasPrefix("sidecar-") else {
            item.select(nil, in: group)
            return
        }
        let selected = item.currentMediaSelection.selectedMediaOption(in: group)
        selectedSubtitleChoiceID = pairs.first(where: { $0.1 == selected })?.0 ?? "off"
        applyNativeSubtitleDefaultIfNeeded(pairs, group: group, item: item)
    }

    private func configureSidecarChoices() {
        sidecarSubtitleByID = Dictionary(
            uniqueKeysWithValues: sidecarSubtitles.map {
                ("sidecar-\($0.id)", $0)
            })
        subtitleChoices = baseSidecarSubtitleChoices
    }

    private var baseSidecarSubtitleChoices: [VideoMediaSelectionChoice] {
        [.init(id: "off", title: "Off")]
            + sidecarSubtitles.map {
                .init(id: "sidecar-\($0.id)", title: $0.label ?? $0.language.uppercased())
            }
    }

    private func applySubtitleDefaults(
        _ settings: VideoSubtitleSettings,
        tvGeneration: Int? = nil
    ) async {
        guard settings.autoEnable,
            let track = VideoSubtitleLanguageMatcher.preferredTrack(
                in: sidecarSubtitles,
                languages: settings.preferredLanguages
            )
        else { return }
        await selectSubtitle(
            id: "sidecar-\(track.id)",
            isExplicit: false,
            tvGeneration: tvGeneration
        )
    }

    #if os(tvOS)
        private func scheduleTVSubtitleDefaults(_ settings: VideoSubtitleSettings) {
            tvSubtitleSelectionTask?.cancel()
            tvSubtitleSelectionGeneration += 1
            let generation = tvSubtitleSelectionGeneration
            tvSubtitleSelectionTask = Task { [weak self] in
                guard let self else { return }
                await applySubtitleDefaults(settings, tvGeneration: generation)
            }
        }
    #endif

    private func isCurrentTVSubtitleSelection(_ generation: Int?) -> Bool {
        #if os(tvOS)
            guard !Task.isCancelled else { return false }
            return generation == nil || generation == tvSubtitleSelectionGeneration
        #else
            return true
        #endif
    }

    private static var supportsAssRenderer: Bool {
        #if os(tvOS)
            false
        #else
            true
        #endif
    }

    private func applyNativeSubtitleDefaultIfNeeded(
        _ pairs: [(String, AVMediaSelectionOption)],
        group: AVMediaSelectionGroup,
        item: AVPlayerItem
    ) {
        guard subtitleSettings.autoEnable,
            !hasExplicitSubtitleSelection,
            !selectedSubtitleChoiceID.hasPrefix("sidecar-")
        else { return }
        let candidates = pairs.map { id, option in
            VideoSubtitleSelectionCandidate(
                id: id,
                language: option.extendedLanguageTag ?? option.locale?.identifier,
                label: option.displayName
            )
        }
        guard
            let identifier = VideoSubtitleLanguageMatcher.preferredIdentifier(
                in: candidates,
                languages: subtitleSettings.preferredLanguages
            ), let option = subtitleOptionsByID[identifier]
        else { return }
        item.select(option, in: group)
        selectedSubtitleChoiceID = identifier
    }

    private func recover(from error: Error?) async {
        guard !usedSafeFallback else {
            errorMessage = error?.localizedDescription ?? "The video could not be played."
            return
        }
        usedSafeFallback = true
        let resumeAt = currentTime
        do {
            let plan = try await service.negotiateVideoPlayback(videoID: videoID, forceTranscode: true)
            install(plan, resumeAt: resumeAt)
            player.play()
        } catch {
            playbackReporter.stop(positionSeconds: currentTime)
            errorMessage = error.localizedDescription
        }
    }

    private func observe(time: CMTime) {
        let seconds = time.seconds
        guard seconds.isFinite else { return }
        currentTime = max(0, seconds)
        playbackReporter.observePlayback(positionSeconds: currentTime, isPlaying: isPlaying)
        activeSubtitleContent = WebVTTSubtitleParser.activeContent(
            at: currentTime,
            cues: activeSubtitleCues
        )
        let itemDuration = player.currentItem?.duration.seconds ?? 0
        if itemDuration.isFinite, itemDuration > 0 { duration = itemDuration }
    }

    func flushPlaybackProgress() {
        playbackReporter.flushProgress(positionSeconds: currentTime, isPaused: !isPlaying)
    }

    func waitForPendingPlaybackReports() async {
        await playbackReporter.waitForPendingReports()
    }
}
