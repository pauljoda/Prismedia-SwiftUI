import Foundation
import Observation

/// Owns queue and transport decisions while delegating media I/O to a platform engine.
@Observable
@MainActor
public final class MusicPlayerController {
    public private(set) var queue: MusicQueue
    public private(set) var isPlaying = false
    public private(set) var errorMessage: String?
    public private(set) var context: MusicPlaybackContext?
    public private(set) var elapsedTime = 0.0
    public private(set) var playbackRate: Float = 1

    /// Narrow bridge for MediaPlayer publication. UI observation remains
    /// property-granular through `@Observable`.
    @ObservationIgnored public var onNowPlayingStateChanged: (() -> Void)?

    private let engine: any AudioPlaybackEngine
    private let service: any MusicPlaybackServicing
    private let stateStore: (any MusicPlaybackStatePersisting)?
    private var preferences: MusicPlaybackPreferences
    private var lastPersistedElapsedTime = 0.0
    private var didAttemptRestoration = false
    private var audiobookCompleted = false
    private var pendingPlaybackReport: Task<Void, Never>?

    public init(
        engine: any AudioPlaybackEngine,
        service: any MusicPlaybackServicing,
        queue: MusicQueue = MusicQueue(tracks: []),
        stateStore: (any MusicPlaybackStatePersisting)? = nil,
        context: MusicPlaybackContext? = nil
    ) {
        self.engine = engine
        self.service = service
        self.queue = queue
        self.stateStore = stateStore
        self.context = context
        preferences = stateStore?.loadPreferences() ?? MusicPlaybackPreferences(queue: queue)
    }

    public var currentTrack: MusicTrack? {
        queue.currentTrack
    }

    public func play(
        tracks: [MusicTrack],
        startingAt trackID: UUID? = nil,
        queueMode: MusicQueueStartMode = .preferred,
        context: MusicPlaybackContext? = nil,
        startSeconds: Double = 0
    ) {
        reportAudiobookProgress(completed: false)
        var previousQueue = queue
        if previousQueue.currentTrack != nil {
            previousQueue.recordCurrentTrackInHistory()
        }
        queue = MusicQueue(
            tracks: tracks,
            startingAt: trackID,
            history: previousQueue.history
        )
        self.context = context
        if context?.isAudiobook != true, playbackRate != 1 {
            playbackRate = 1
            engine.setPlaybackRate(playbackRate)
        }
        audiobookCompleted = false
        queue.setRepeatMode(preferences.repeatMode)
        queue.setShuffled(shuffleEnabled(for: queueMode, context: context))
        elapsedTime = max(0, startSeconds.isFinite ? startSeconds : 0)
        startCurrentTrack()
        persistState()
    }

    public func resume() {
        guard currentTrack != nil else { return }
        if context?.isAudiobook == true { audiobookCompleted = false }
        errorMessage = nil
        engine.play()
        isPlaying = true
        publishNowPlayingState()
        persistProgress()
    }

    public func pause() {
        engine.pause()
        isPlaying = false
        reportAudiobookProgress(completed: false)
        publishNowPlayingState()
        persistProgress()
    }

    public func clearPlayback() {
        reportAudiobookProgress(completed: false)
        engine.pause()
        queue = MusicQueue(tracks: [])
        isPlaying = false
        errorMessage = nil
        context = nil
        elapsedTime = 0
        lastPersistedElapsedTime = 0
        audiobookCompleted = false
        playbackRate = 1
        engine.setPlaybackRate(playbackRate)
        stateStore?.clear()
        publishNowPlayingState()
    }

    public func setPlaybackRate(_ rate: Float) {
        guard rate.isFinite else { return }
        playbackRate = min(max(rate, 0.5), 3)
        engine.setPlaybackRate(playbackRate)
        publishNowPlayingState()
    }

    public func seek(to seconds: Double) {
        if context?.isAudiobook == true { audiobookCompleted = false }
        elapsedTime = max(0, seconds)
        engine.seek(to: elapsedTime)
        reportAudiobookProgress(completed: false)
        persistProgress()
    }

    public func skipToNext() {
        reportAudiobookProgress(completed: false)
        guard queue.advance(reason: .user) != nil else { return }
        elapsedTime = 0
        startCurrentTrack()
        persistState()
    }

    public func skipToPrevious() {
        reportAudiobookProgress(completed: false)
        guard queue.movePrevious() != nil else { return }
        elapsedTime = 0
        startCurrentTrack()
        persistState()
    }

    public func skipToUpcomingTrack(id trackID: UUID) {
        reportAudiobookProgress(completed: false)
        guard queue.moveToUpcomingTrack(id: trackID) != nil else { return }
        elapsedTime = 0
        startCurrentTrack()
        persistState()
    }

    public func moveUpcomingTrack(id trackID: UUID, before destinationID: UUID) {
        guard queue.moveUpcomingTrack(id: trackID, before: destinationID) else { return }
        publishNowPlayingState()
        persistState()
    }

    public func moveUpcomingTrack(id trackID: UUID, after destinationID: UUID) {
        guard queue.moveUpcomingTrack(id: trackID, after: destinationID) else { return }
        publishNowPlayingState()
        persistState()
    }

    public func setRepeatMode(_ mode: MusicRepeatMode) {
        queue.setRepeatMode(mode)
        preferences.repeatMode = mode
        persistPreferences()
        publishNowPlayingState()
        persistState()
    }

    public func cycleRepeatMode() {
        var nextQueue = queue
        nextQueue.cycleRepeatMode()
        setRepeatMode(nextQueue.repeatMode)
    }

    public func setShuffleEnabled(_ enabled: Bool) {
        guard context?.isAudiobook != true else { return }
        queue.setShuffled(enabled)
        preferences.isShuffled = enabled
        persistPreferences()
        publishNowPlayingState()
        persistState()
    }

    public func clearHistory() {
        queue.clearHistory()
        persistState()
    }

    public func handlePlaybackEnded() async {
        guard let completedTrack = currentTrack else { return }
        let isAudiobook = context?.isAudiobook == true
        let completedAudiobook = isAudiobook && queue.orderedTracks.last?.id == completedTrack.id

        if isAudiobook {
            audiobookCompleted = completedAudiobook
            let finishedPosition = completedTrack.duration ?? elapsedTime
            reportAudiobookProgress(
                completed: completedAudiobook,
                trackOffsetSeconds: finishedPosition
            )
        }

        if queue.advance(reason: .playbackEnded) != nil {
            elapsedTime = 0
            startCurrentTrack()
        } else {
            isPlaying = false
            publishNowPlayingState()
        }

        if !isAudiobook {
            try? await service.recordAudioTrackPlay(id: completedTrack.id)
        }
        persistState()
    }

    public func restoreIfNeeded() {
        guard !didAttemptRestoration else { return }
        didAttemptRestoration = true
        guard let restoration = stateStore?.load(), !restoration.tracks.isEmpty else { return }
        context = restoration.context
        audiobookCompleted = restoration.audiobookCompleted ?? false
        queue = MusicQueue(restoration: restoration)
        elapsedTime = restoration.elapsedTime
        lastPersistedElapsedTime = restoration.elapsedTime
        guard let currentTrack,
            let url = service.audioStreamURL(for: currentTrack.id)
        else { return }
        engine.load(url: url)
        engine.setPlaybackRate(playbackRate)
        if elapsedTime > 0 { engine.seek(to: elapsedTime) }
        isPlaying = false
        publishNowPlayingState()
    }

    public func updateElapsedTime(_ seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        elapsedTime = seconds
        guard abs(seconds - lastPersistedElapsedTime) >= 5 else { return }
        reportAudiobookProgress(completed: false)
        persistProgress()
    }

    public func flushPendingPlaybackReports() async {
        await pendingPlaybackReport?.value
    }

    public func flushAudiobookProgress() async {
        reportAudiobookProgress(completed: false)
        persistProgress()
        await flushPendingPlaybackReports()
    }

    public func setAudiobookCompletionState(_ completed: Bool) {
        guard context?.isAudiobook == true else { return }
        audiobookCompleted = completed
        if completed {
            engine.pause()
            isPlaying = false
            publishNowPlayingState()
            persistProgress()
        }
    }

    private func startCurrentTrack() {
        guard let currentTrack else {
            isPlaying = false
            publishNowPlayingState()
            return
        }
        guard let url = service.audioStreamURL(for: currentTrack.id) else {
            errorMessage = "This track does not have a playable stream."
            isPlaying = false
            publishNowPlayingState()
            return
        }

        errorMessage = nil
        engine.load(url: url)
        engine.setPlaybackRate(playbackRate)
        if elapsedTime > 0 { engine.seek(to: elapsedTime) }
        engine.play()
        isPlaying = true
        publishNowPlayingState()
    }

    private func publishNowPlayingState() {
        onNowPlayingStateChanged?()
    }

    private func shuffleEnabled(
        for queueMode: MusicQueueStartMode,
        context: MusicPlaybackContext?
    ) -> Bool {
        guard context?.isAudiobook != true else { return false }

        switch queueMode {
        case .preferred:
            return preferences.isShuffled
        case .ordered:
            preferences.isShuffled = false
        case .shuffled:
            preferences.isShuffled = true
        }
        persistPreferences()
        return preferences.isShuffled
    }

    private func persistPreferences() {
        stateStore?.savePreferences(preferences)
    }

    private func persistState() {
        defer { lastPersistedElapsedTime = elapsedTime }
        guard let stateStore else { return }
        guard !queue.tracks.isEmpty else {
            stateStore.clear()
            return
        }
        stateStore.save(
            MusicPlaybackRestoration(
                queue: queue,
                elapsedTime: elapsedTime,
                context: context,
                audiobookCompleted: audiobookCompleted
            )
        )
    }

    private func persistProgress() {
        defer { lastPersistedElapsedTime = elapsedTime }
        guard let stateStore, !queue.tracks.isEmpty else { return }
        stateStore.saveProgress(
            MusicPlaybackProgressCheckpoint(
                currentTrackID: currentTrack?.id,
                elapsedTime: elapsedTime,
                audiobookCompleted: audiobookCompleted
            )
        )
    }

    private func reportAudiobookProgress(
        completed: Bool,
        trackOffsetSeconds: Double? = nil
    ) {
        guard let context,
            context.isAudiobook,
            let ownerID = context.playbackOwnerEntityID,
            let currentTrack,
            completed || !audiobookCompleted
        else { return }

        let resumeSeconds =
            completed
            ? 0
            : AudiobookPlaybackProjection.absoluteTime(
                in: queue.tracks,
                trackID: currentTrack.id,
                trackOffsetSeconds: trackOffsetSeconds ?? elapsedTime
            )
        let previous = pendingPlaybackReport
        let service = self.service
        pendingPlaybackReport = Task {
            await previous?.value
            try? await service.updateEntityPlayback(
                id: ownerID,
                resumeSeconds: resumeSeconds,
                completed: completed
            )
        }
    }
}
