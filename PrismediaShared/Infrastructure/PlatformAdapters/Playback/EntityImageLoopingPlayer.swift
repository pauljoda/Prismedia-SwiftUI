import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class EntityImageLoopingPlayer {
    private(set) var isReady = false
    private(set) var progress = 0.0
    private(set) var presentationSize = CGSize.zero

    @ObservationIgnored let player: AVQueuePlayer
    @ObservationIgnored private var looper: AVPlayerLooper?
    @ObservationIgnored private var loadedURL: URL?
    @ObservationIgnored private var currentItemObservation: NSKeyValueObservation?
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    @ObservationIgnored private var presentationSizeObservation: NSKeyValueObservation?
    @ObservationIgnored nonisolated(unsafe) private var timeObserver: Any?

    init() {
        let player = AVQueuePlayer()
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
        observeProgress()
    }

    isolated deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }

    func load(url: URL) {
        guard loadedURL != url else { return }
        unload()
        loadedURL = url
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        observeCurrentItem()
    }

    func setPlaybackAllowed(_ isAllowed: Bool) {
        if isAllowed {
            player.play()
        } else {
            player.pause()
        }
    }

    func setMuted(_ isMuted: Bool) {
        player.isMuted = isMuted
    }

    func unload() {
        player.pause()
        statusObservation = nil
        presentationSizeObservation = nil
        currentItemObservation = nil
        looper?.disableLooping()
        looper = nil
        player.removeAllItems()
        loadedURL = nil
        isReady = false
        progress = 0
        presentationSize = .zero
    }

    private func observeCurrentItem() {
        currentItemObservation = player.observe(\.currentItem, options: [.initial, .new]) {
            [weak self] player, _ in
            Task { @MainActor [weak self] in
                self?.observeStatus(of: player.currentItem)
            }
        }
    }

    private func observeStatus(of item: AVPlayerItem?) {
        statusObservation = nil
        presentationSizeObservation = nil
        guard let item else {
            isReady = false
            presentationSize = .zero
            return
        }
        presentationSizeObservation = item.observe(
            \.presentationSize,
            options: [.initial, .new]
        ) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.updatePresentationSize(for: item)
            }
        }
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isReady = item.status == .readyToPlay
                updatePresentationSize(for: item)
            }
        }
    }

    private func updatePresentationSize(for item: AVPlayerItem) {
        presentationSize = item.status == .readyToPlay ? item.presentationSize : .zero
    }

    private func observeProgress() {
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] time in
            Task { @MainActor [weak self] in
                self?.updateProgress(time: time)
            }
        }
    }

    private func updateProgress(time: CMTime) {
        guard
            time.seconds.isFinite,
            let duration = player.currentItem?.duration.seconds,
            duration.isFinite,
            duration > 0
        else { return }
        progress = min(1, max(0, time.seconds / duration))
    }
}
