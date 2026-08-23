#if os(iOS) || os(macOS)
    import AVFoundation
    import Foundation
    import Observation
    import OSLog

    @Observable
    @MainActor
    public final class AVPlayerAudioPlaybackEngine: NSObject, AudioPlaybackEngine {
        public private(set) var elapsedTime: Double = 0
        public private(set) var duration: Double = 0
        public private(set) var isBuffering = false
        public private(set) var isPlaybackAdvancing = false

        @ObservationIgnored public var onPlaybackEnded: (() -> Void)?
        @ObservationIgnored public var onPlaybackFailed: (() -> Void)?
        @ObservationIgnored public var onNowPlayingProgressChanged: (() -> Void)?

        let player: AVPlayer
        #if os(iOS)
            private let audioSession = MusicPlaybackAudioSession()
        #endif
        @ObservationIgnored
        nonisolated(unsafe) private var timeObserver: Any?
        @ObservationIgnored
        nonisolated(unsafe) private var endObserver: NSObjectProtocol?
        @ObservationIgnored
        nonisolated(unsafe) private var failedToEndObserver: NSObjectProtocol?
        @ObservationIgnored private var statusObservation: NSKeyValueObservation?
        @ObservationIgnored private var timeControlStatusObservation: NSKeyValueObservation?
        @ObservationIgnored private var playbackStartTask: Task<Void, Never>?
        @ObservationIgnored private var wantsToPlay = false
        @ObservationIgnored private var playbackRate: Float = 1
        @ObservationIgnored private var failedItemIdentifier: ObjectIdentifier?

        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "Prismedia",
            category: "AudioPlayback"
        )

        public override init() {
            player = AVPlayer()
            super.init()
            observeTime()
            observeTimeControlStatus()
        }

        deinit {
            playbackStartTask?.cancel()
            if let timeObserver { player.removeTimeObserver(timeObserver) }
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            if let failedToEndObserver {
                NotificationCenter.default.removeObserver(failedToEndObserver)
            }
        }

        public func load(url: URL) {
            removeItemObservers()
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            observe(item)
            elapsedTime = 0
            duration = 0
            failedItemIdentifier = nil
        }

        public func play() {
            wantsToPlay = true
            #if os(iOS)
                Task { [weak self, audioSession] in
                    await audioSession.activate()
                    guard !Task.isCancelled else { return }
                    guard self?.wantsToPlay == true else { return }
                    guard let self else { return }
                    self.player.playImmediately(atRate: self.playbackRate)
                    self.watchForPlaybackStart(of: self.player.currentItem)
                }
            #else
                player.playImmediately(atRate: playbackRate)
                watchForPlaybackStart(of: player.currentItem)
            #endif
        }

        public func pause() {
            wantsToPlay = false
            playbackStartTask?.cancel()
            playbackStartTask = nil
            player.pause()
        }

        public func seek(to seconds: Double) {
            let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
            player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        public func setPlaybackRate(_ rate: Float) {
            guard rate.isFinite else { return }
            playbackRate = min(max(rate, 0.5), 3)
            if wantsToPlay {
                player.rate = playbackRate
            }
        }

        private func observeTime() {
            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                Task { @MainActor [weak self] in self?.updateTime(time) }
            }
        }

        private func observeTimeControlStatus() {
            timeControlStatusObservation = player.observe(
                \.timeControlStatus,
                options: [.initial, .new]
            ) { [weak self] player, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let isAdvancing = player.timeControlStatus == .playing
                    guard self.isPlaybackAdvancing != isAdvancing else { return }
                    self.isPlaybackAdvancing = isAdvancing
                    self.onNowPlayingProgressChanged?()
                }
            }
        }

        private func observe(_ item: AVPlayerItem) {
            statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                Task { @MainActor in
                    self?.isBuffering = item.status == .unknown
                    self?.updateDuration(item.duration)
                    if item.status == .failed {
                        self?.reportFailure(
                            for: item,
                            error: item.error ?? Self.playbackFailureError()
                        )
                    }
                }
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.onPlaybackEnded?() }
            }
            failedToEndObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] notification in
                let error =
                    notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? any Error
                    ?? item.error
                    ?? Self.playbackFailureError()
                Task { @MainActor in
                    self?.reportFailure(for: item, error: error)
                }
            }
        }

        private func removeItemObservers() {
            playbackStartTask?.cancel()
            playbackStartTask = nil
            statusObservation = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
            if let failedToEndObserver {
                NotificationCenter.default.removeObserver(failedToEndObserver)
            }
            failedToEndObserver = nil
            failedItemIdentifier = nil
        }

        private func watchForPlaybackStart(of item: AVPlayerItem?) {
            playbackStartTask?.cancel()
            guard let item else { return }
            playbackStartTask = Task { @MainActor [weak self, weak item] in
                guard let self, let item else { return }
                var previousPosition = self.player.currentTime().seconds
                for _ in 0..<15 {
                    do {
                        try await Task.sleep(for: .seconds(1))
                    } catch {
                        return
                    }
                    guard self.wantsToPlay,
                        self.player.currentItem === item
                    else { return }
                    let currentPosition = self.player.currentTime().seconds
                    if self.player.timeControlStatus == .playing,
                        previousPosition.isFinite,
                        currentPosition.isFinite,
                        currentPosition - previousPosition >= 0.1
                    {
                        return
                    }
                    previousPosition = currentPosition
                }

                self.reportFailure(for: item, error: Self.playbackStartTimeoutError())
            }
        }

        private func reportFailure(for item: AVPlayerItem, error: any Error) {
            guard wantsToPlay, player.currentItem === item else { return }
            let itemIdentifier = ObjectIdentifier(item)
            guard failedItemIdentifier != itemIdentifier else { return }
            failedItemIdentifier = itemIdentifier
            wantsToPlay = false
            playbackStartTask?.cancel()
            playbackStartTask = nil
            player.pause()
            isBuffering = false
            if isPlaybackAdvancing {
                isPlaybackAdvancing = false
                onNowPlayingProgressChanged?()
            }

            let failure = error as NSError
            Self.logger.error(
                "Audio playback failed domain=\(failure.domain, privacy: .public) code=\(failure.code)"
            )
            onPlaybackFailed?()
        }

        nonisolated private static func playbackFailureError() -> NSError {
            NSError(
                domain: "Prismedia.AudioPlayback",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The audio stream could not be played."]
            )
        }

        nonisolated private static func playbackStartTimeoutError() -> NSError {
            NSError(
                domain: "Prismedia.AudioPlayback",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "The audio stream did not start."]
            )
        }

        private func updateTime(_ time: CMTime) {
            guard time.seconds.isFinite else { return }
            let previousElapsedTime = elapsedTime
            let previousDuration = duration
            elapsedTime = max(0, time.seconds)
            if let item = player.currentItem {
                updateDuration(item.duration, publishesChange: false)
            }
            guard elapsedTime != previousElapsedTime || duration != previousDuration else { return }
            onNowPlayingProgressChanged?()
        }

        private func updateDuration(_ time: CMTime, publishesChange: Bool = true) {
            guard time.seconds.isFinite, time.seconds > 0 else { return }
            guard duration != time.seconds else { return }
            duration = time.seconds
            if publishesChange { onNowPlayingProgressChanged?() }
        }
    }

#endif
