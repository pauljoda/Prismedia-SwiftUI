#if os(iOS) || os(macOS)
    import AVFoundation
    import Foundation
    import Observation

    @Observable
    @MainActor
    public final class AVPlayerAudioPlaybackEngine: NSObject, AudioPlaybackEngine {
        public private(set) var elapsedTime: Double = 0
        public private(set) var duration: Double = 0
        public private(set) var isBuffering = false

        @ObservationIgnored public var onPlaybackEnded: (() -> Void)?
        @ObservationIgnored public var onNowPlayingProgressChanged: (() -> Void)?

        let player: AVPlayer
        #if os(iOS)
            private let audioSession = MusicPlaybackAudioSession()
        #endif
        @ObservationIgnored
        nonisolated(unsafe) private var timeObserver: Any?
        @ObservationIgnored
        nonisolated(unsafe) private var endObserver: NSObjectProtocol?
        @ObservationIgnored private var statusObservation: NSKeyValueObservation?
        @ObservationIgnored private var wantsToPlay = false

        public override init() {
            player = AVPlayer()
            super.init()
            observeTime()
        }

        deinit {
            if let timeObserver { player.removeTimeObserver(timeObserver) }
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        }

        public func load(url: URL) {
            removeItemObservers()
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            observe(item)
            elapsedTime = 0
            duration = 0
        }

        public func play() {
            wantsToPlay = true
            #if os(iOS)
                Task { [weak self, audioSession] in
                    await audioSession.activate()
                    guard !Task.isCancelled else { return }
                    guard self?.wantsToPlay == true else { return }
                    self?.player.play()
                }
            #else
                player.play()
            #endif
        }

        public func pause() {
            wantsToPlay = false
            player.pause()
        }

        public func seek(to seconds: Double) {
            let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
            player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        private func observeTime() {
            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                Task { @MainActor [weak self] in self?.updateTime(time) }
            }
        }

        private func observe(_ item: AVPlayerItem) {
            statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                Task { @MainActor in
                    self?.isBuffering = item.status == .unknown
                    self?.updateDuration(item.duration)
                }
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.onPlaybackEnded?() }
            }
        }

        private func removeItemObservers() {
            statusObservation = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
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
