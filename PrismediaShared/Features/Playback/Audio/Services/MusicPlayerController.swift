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
    public private(set) var resolvedTrackDuration = 0.0
    public private(set) var isPlaybackAdvancing = false
    public private(set) var playbackRate: Float = 1

    /// Narrow bridge for MediaPlayer publication. UI observation remains
    /// property-granular through `@Observable`.
    @ObservationIgnored public var onNowPlayingStateChanged: (() -> Void)?

    private let engine: any AudioPlaybackEngine
    private let service: any MusicPlaybackServicing
    private let playbackClock: any MusicPlaybackClock
    private let stateStore: (any MusicPlaybackStatePersisting)?
    private var preferences: MusicPlaybackPreferences
    private var lastPersistedElapsedTime = 0.0
    private var didAttemptRestoration = false
    private var audiobookCompleted = false
    private var pendingPlaybackReport: Task<Void, Never>?
    private var loadedTrackID: MusicTrack.ID?
    private var resumesWhenPlaybackBecomesAvailable = false
    private var activeQueueID = UUID()
    private var currentTrackRequestedAt: TimeInterval?
    private var consumptionActivityClock = ConsumptionActivityClock()
    private var accessedConsumptionEntityID: UUID?
    private var isReaderPlaybackRateControlActive = false

    private static let quickSkipThreshold: TimeInterval = 10

    public convenience init(
        engine: any AudioPlaybackEngine,
        service: any MusicPlaybackServicing,
        queue: MusicQueue = MusicQueue(tracks: []),
        stateStore: (any MusicPlaybackStatePersisting)? = nil,
        context: MusicPlaybackContext? = nil
    ) {
        self.init(
            engine: engine,
            service: service,
            playbackClock: SystemMusicPlaybackClock(),
            queue: queue,
            stateStore: stateStore,
            context: context
        )
    }

    init(
        engine: any AudioPlaybackEngine,
        service: any MusicPlaybackServicing,
        playbackClock: any MusicPlaybackClock,
        queue: MusicQueue = MusicQueue(tracks: []),
        stateStore: (any MusicPlaybackStatePersisting)? = nil,
        context: MusicPlaybackContext? = nil
    ) {
        self.engine = engine
        self.service = service
        self.playbackClock = playbackClock
        self.queue = queue
        self.stateStore = stateStore
        self.context = context
        preferences = stateStore?.loadPreferences() ?? MusicPlaybackPreferences(queue: queue)
    }

    public var currentTrack: MusicTrack? {
        queue.currentTrack
    }

    public var currentQueueID: UUID {
        activeQueueID
    }

    public var currentTrackDuration: Double {
        let duration = resolvedTrackDuration > 0
            ? resolvedTrackDuration
            : currentTrack?.duration ?? 0
        return max(duration, elapsedTime, 1)
    }

    public func play(
        tracks: [MusicTrack],
        startingAt trackID: UUID? = nil,
        queueMode: MusicQueueStartMode = .preferred,
        context: MusicPlaybackContext? = nil,
        startSeconds: Double = 0
    ) {
        guard tracks.contains(where: \.isPlayable) else { return }
        preparePlayback(
            tracks: tracks,
            startingAt: trackID,
            queueMode: queueMode,
            context: context,
            startSeconds: startSeconds
        )
        resume()
    }

    @discardableResult
    public func preparePlayback(
        tracks: [MusicTrack],
        startingAt trackID: UUID? = nil,
        queueMode: MusicQueueStartMode = .preferred,
        context: MusicPlaybackContext? = nil,
        startSeconds: Double = 0
    ) -> UUID {
        let tracks = tracks.filter(\.isPlayable)
        guard !tracks.isEmpty else { return activeQueueID }
        reportCurrentConsumption(stopsActivity: true)
        if currentTrack != nil { engine.pause() }
        var previousQueue = queue
        if previousQueue.currentTrack != nil {
            previousQueue.recordCurrentTrackInHistory()
        }
        queue = MusicQueue(
            tracks: tracks,
            startingAt: trackID,
            history: previousQueue.history
        )
        activeQueueID = UUID()
        let preservesPlaybackRate = context?.isAudiobook == true
            && context?.playbackOwnerEntityID == self.context?.playbackOwnerEntityID
        if !preservesPlaybackRate, playbackRate != 1 {
            playbackRate = 1
            engine.setPlaybackRate(playbackRate)
        }
        self.context = context
        accessedConsumptionEntityID = nil
        audiobookCompleted = false
        if preferences.repeatMode == .one {
            preferences.repeatMode = .all
            persistPreferences()
        }
        queue.setRepeatMode(preferences.repeatMode)
        let shouldShuffle = shuffleEnabled(for: queueMode, context: context)
        if queueMode == .shuffled, shouldShuffle {
            queue.shuffleAll()
        } else {
            queue.setShuffled(shouldShuffle)
        }
        elapsedTime = max(0, startSeconds.isFinite ? startSeconds : 0)
        resolvedTrackDuration = 0
        isPlaybackAdvancing = false
        loadedTrackID = nil
        currentTrackRequestedAt = nil
        resumesWhenPlaybackBecomesAvailable = false
        isPlaying = false
        publishNowPlayingState()
        persistState()
        return activeQueueID
    }

    @discardableResult
    public func appendUpcomingTracks(_ tracks: [MusicTrack], to queueID: UUID) -> Bool {
        guard queueID == activeQueueID else { return false }
        let previousCount = queue.tracks.count
        let couldGoNext = queue.canGoNext
        let previousRepeatMode = queue.repeatMode
        queue.appendUpcomingTracks(tracks)
        guard queue.tracks.count != previousCount else { return true }
        syncRepeatPreferenceFromQueue()
        if queue.canGoNext != couldGoNext || queue.repeatMode != previousRepeatMode {
            publishNowPlayingState()
        }
        return true
    }

    public func finishQueueExpansion(_ queueID: UUID) {
        guard queueID == activeQueueID else { return }
        persistState()
    }

    public func resume() {
        guard currentTrack != nil else { return }
        if context?.isAudiobook == true { audiobookCompleted = false }
        guard prepareCurrentTrack() else {
            resumesWhenPlaybackBecomesAvailable = !service.isPlaybackAvailable
            return
        }
        resumesWhenPlaybackBecomesAvailable = false
        errorMessage = nil
        engine.play()
        isPlaying = true
        beginCurrentConsumption()
        publishNowPlayingState()
        persistProgress()
    }

    public func pause() {
        resumesWhenPlaybackBecomesAvailable = false
        engine.pause()
        isPlaying = false
        reportCurrentConsumption(stopsActivity: true)
        isPlaybackAdvancing = false
        publishNowPlayingState()
        persistProgress()
    }

    public func clearPlayback() {
        reportCurrentConsumption(stopsActivity: true)
        resetPlaybackState()
    }

    public func discardPlaybackState() {
        pendingPlaybackReport?.cancel()
        pendingPlaybackReport = nil
        resetPlaybackState()
    }

    private func resetPlaybackState() {
        engine.pause()
        queue = MusicQueue(tracks: [])
        activeQueueID = UUID()
        isPlaying = false
        errorMessage = nil
        context = nil
        elapsedTime = 0
        resolvedTrackDuration = 0
        isPlaybackAdvancing = false
        lastPersistedElapsedTime = 0
        audiobookCompleted = false
        playbackRate = 1
        loadedTrackID = nil
        currentTrackRequestedAt = nil
        resumesWhenPlaybackBecomesAvailable = false
        consumptionActivityClock = ConsumptionActivityClock()
        accessedConsumptionEntityID = nil
        engine.setPlaybackRate(playbackRate)
        stateStore?.clear()
        publishNowPlayingState()
    }

    /// Marks whether Reader Mode currently owns variable-speed audiobook playback.
    /// Leaving Reader Mode preserves the current rate but makes it read-only until
    /// Reader Mode becomes active again or the playback context changes.
    public func setReaderPlaybackRateControlActive(_ isActive: Bool) {
        isReaderPlaybackRateControlActive = isActive
    }

    /// Applies a variable audiobook playback rate while Reader Mode is active.
    public func setPlaybackRate(_ rate: Float) {
        guard isReaderPlaybackRateControlActive,
            context?.isAudiobook == true,
            rate.isFinite
        else { return }
        playbackRate = min(max(rate, 0.5), 3)
        engine.setPlaybackRate(playbackRate)
        publishNowPlayingState()
    }

    public func seek(to seconds: Double) {
        if context?.isAudiobook == true { audiobookCompleted = false }
        elapsedTime = max(0, seconds)
        engine.seek(to: elapsedTime)
        reportCurrentConsumption()
        persistProgress()
    }

    public func skipToNext() {
        reportCurrentConsumption()
        let skippedTrack = currentTrack
        let skippedPosition = elapsedTime
        guard queue.advance(reason: .user) != nil else { return }
        syncRepeatPreferenceFromQueue()
        reportQuickSkipIfNeeded(track: skippedTrack, positionSeconds: skippedPosition)
        elapsedTime = 0
        startCurrentTrack()
        persistState()
    }

    public func skipToPrevious() {
        reportCurrentConsumption()
        guard queue.movePrevious() != nil else { return }
        syncRepeatPreferenceFromQueue()
        elapsedTime = 0
        startCurrentTrack()
        persistState()
    }

    public func skipToUpcomingTrack(id trackID: UUID) {
        reportCurrentConsumption()
        let skippedTrack = currentTrack
        let skippedPosition = elapsedTime
        guard queue.moveToUpcomingTrack(id: trackID) != nil else { return }
        syncRepeatPreferenceFromQueue()
        reportQuickSkipIfNeeded(track: skippedTrack, positionSeconds: skippedPosition)
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

    private func syncRepeatPreferenceFromQueue() {
        guard preferences.repeatMode != queue.repeatMode else { return }
        preferences.repeatMode = queue.repeatMode
        persistPreferences()
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
            let finishedPosition = reportingTrackDuration ?? elapsedTime
            reportAudiobookProgress(
                completed: completedAudiobook,
                trackOffsetSeconds: finishedPosition,
                stopsActivity: completedAudiobook
            )
        } else {
            reportMusicProgress(track: completedTrack, stopsActivity: true)
        }

        if queue.advance(reason: .playbackEnded) != nil {
            elapsedTime = 0
            startCurrentTrack()
        } else {
            isPlaying = false
            isPlaybackAdvancing = false
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
        let restoredQueue = MusicQueue(restoration: restoration)
        guard let restoredTrack = restoredQueue.currentTrack else {
            stateStore?.clear()
            return
        }
        context = restoration.context
        audiobookCompleted = restoration.audiobookCompleted ?? false
        queue = restoredQueue
        activeQueueID = UUID()
        let restoredElapsedTime = restoredTrack.id == restoration.currentTrackID ? restoration.elapsedTime : 0
        elapsedTime = restoredElapsedTime
        resolvedTrackDuration = 0
        isPlaybackAdvancing = false
        lastPersistedElapsedTime = restoredElapsedTime
        _ = prepareCurrentTrack()
        isPlaying = false
        publishNowPlayingState()
    }

    public func playbackServiceDidConnect() {
        guard currentTrack != nil else { return }
        let shouldResume = resumesWhenPlaybackBecomesAvailable
        guard prepareCurrentTrack() else { return }
        resumesWhenPlaybackBecomesAvailable = false
        if shouldResume {
            engine.play()
            isPlaying = true
            beginCurrentConsumption()
        }
        publishNowPlayingState()
    }

    func playbackServiceDidDisconnect() {
        guard currentTrack != nil else { return }
        pause()
        loadedTrackID = nil
        currentTrackRequestedAt = nil
    }

    public func updateElapsedTime(_ seconds: Double) {
        updatePlaybackProgress(
            elapsedTime: seconds,
            duration: nil,
            isAdvancing: isPlaying
        )
    }

    public func updatePlaybackProgress(
        elapsedTime seconds: Double,
        duration: Double?,
        isAdvancing: Bool
    ) {
        guard seconds.isFinite, seconds >= 0 else { return }
        elapsedTime = seconds
        if let duration, duration.isFinite, duration > 0 {
            resolvedTrackDuration = duration
        }

        let isActivelyAdvancing = isPlaying && isAdvancing
        if isActivelyAdvancing {
            beginCurrentConsumption(startActivity: true)
        } else if isPlaybackAdvancing {
            reportCurrentConsumption(stopsActivity: true)
            isPlaybackAdvancing = false
            persistProgress()
            return
        }
        isPlaybackAdvancing = isActivelyAdvancing
        guard abs(seconds - lastPersistedElapsedTime) >= 5 else { return }
        reportCurrentConsumption()
        persistProgress()
    }

    public func flushPendingPlaybackReports() async {
        await pendingPlaybackReport?.value
    }

    public func flushAudiobookProgress() async {
        reportAudiobookProgress(completed: false, stopsActivity: true)
        persistProgress()
        await flushPendingPlaybackReports()
    }

    public func resumeAudiobookActivity() {
        guard isPlaybackAdvancing, context?.isAudiobook == true else { return }
        consumptionActivityClock.start(at: playbackClock.now)
    }

    public func setAudiobookCompletionState(_ completed: Bool) {
        guard context?.isAudiobook == true else { return }
        if completed {
            reportCurrentConsumption(stopsActivity: true)
        }
        audiobookCompleted = completed
        if completed {
            engine.pause()
            isPlaying = false
            isPlaybackAdvancing = false
            publishNowPlayingState()
            persistProgress()
        }
    }

    private func startCurrentTrack() {
        guard currentTrack != nil else {
            isPlaying = false
            publishNowPlayingState()
            return
        }
        resolvedTrackDuration = 0
        isPlaybackAdvancing = false
        consumptionActivityClock = ConsumptionActivityClock()
        loadedTrackID = nil
        currentTrackRequestedAt = nil
        guard prepareCurrentTrack() else {
            resumesWhenPlaybackBecomesAvailable = !service.isPlaybackAvailable
            isPlaying = false
            publishNowPlayingState()
            return
        }

        resumesWhenPlaybackBecomesAvailable = false
        errorMessage = nil
        engine.play()
        isPlaying = true
        beginCurrentConsumption()
        publishNowPlayingState()
    }

    private func prepareCurrentTrack() -> Bool {
        guard let currentTrack else { return false }
        guard currentTrack.isPlayable else { return false }
        guard service.isPlaybackAvailable else { return false }
        guard let url = service.audioStreamURL(for: currentTrack.id) else {
            errorMessage = "This track does not have a playable stream."
            loadedTrackID = nil
            return false
        }
        guard loadedTrackID != currentTrack.id else { return true }
        engine.load(url: url)
        currentTrackRequestedAt = playbackClock.now
        engine.setPlaybackRate(playbackRate)
        if elapsedTime > 0 { engine.seek(to: elapsedTime) }
        loadedTrackID = currentTrack.id
        return true
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
        trackOffsetSeconds: Double? = nil,
        stopsActivity: Bool = false
    ) {
        guard let context,
            context.isAudiobook,
            let ownerID = context.playbackOwnerEntityID,
            let currentTrack,
            completed || !audiobookCompleted
        else { return }

        guard let mapping = context.bookProgressMappings?.first(where: {
            $0.trackID == currentTrack.id
        }),
            let duration = reportingTrackDuration
        else {
            if stopsActivity { _ = consumptionActivityClock.stop(at: playbackClock.now) }
            return
        }
        let activitySeconds = stopsActivity
            ? consumptionActivityClock.stop(at: playbackClock.now)
            : isPlaybackAdvancing
                ? consumptionActivityClock.take(at: playbackClock.now)
                : nil
        let request = BookProgressMappingResolver().progressRequest(
            mapping: mapping,
            offsetSeconds: trackOffsetSeconds ?? elapsedTime,
            durationSeconds: duration,
            activitySeconds: activitySeconds,
            completed: completed
        )
        enqueuePlaybackReport { service in
            try? await service.updateEntityProgress(
                id: ownerID,
                request: request
            )
        }
    }

    private func reportCurrentConsumption(stopsActivity: Bool = false) {
        if context?.isAudiobook == true {
            reportAudiobookProgress(completed: false, stopsActivity: stopsActivity)
        } else {
            reportMusicProgress(track: currentTrack, stopsActivity: stopsActivity)
        }
    }

    private func beginCurrentConsumption(startActivity: Bool = false) {
        guard let currentTrack else { return }
        let entityID = context?.isAudiobook == true
            ? context?.playbackOwnerEntityID
            : currentTrack.id
        guard let entityID else { return }

        if accessedConsumptionEntityID != entityID {
            let sessionID = UUID().uuidString.lowercased()
            accessedConsumptionEntityID = entityID
            let isAudiobook = context?.isAudiobook == true
            let position = elapsedTime
            let duration = reportingTrackDuration
            enqueuePlaybackReport { service in
                try? await service.recordEntityPlaybackEvent(
                    id: entityID,
                    kind: .accessed,
                    positionSeconds: isAudiobook ? nil : position,
                    durationSeconds: isAudiobook ? nil : duration,
                    sessionID: sessionID
                )
            }
        }

        if startActivity {
            consumptionActivityClock.start(at: playbackClock.now)
        }
    }

    private func reportMusicProgress(
        track: MusicTrack?,
        stopsActivity: Bool
    ) {
        guard context?.isAudiobook != true, let track else {
            if stopsActivity { _ = consumptionActivityClock.stop(at: playbackClock.now) }
            return
        }
        let activitySeconds = stopsActivity
            ? consumptionActivityClock.stop(at: playbackClock.now)
            : isPlaybackAdvancing
                ? consumptionActivityClock.take(at: playbackClock.now)
                : nil
        let position = elapsedTime
        enqueuePlaybackReport { service in
            try? await service.updateEntityPlayback(
                id: track.id,
                resumeSeconds: position,
                activitySeconds: activitySeconds,
                completed: nil
            )
        }
    }

    private func reportQuickSkipIfNeeded(track: MusicTrack?, positionSeconds: Double) {
        guard context?.isAudiobook != true,
            let track,
            let currentTrackRequestedAt,
            positionSeconds <= Self.quickSkipThreshold,
            playbackClock.now - currentTrackRequestedAt <= Self.quickSkipThreshold
        else { return }

        enqueuePlaybackReport { service in
            try? await service.recordEntityPlaybackEvent(
                id: track.id,
                kind: .skipped,
                positionSeconds: positionSeconds,
                durationSeconds: track.duration,
                sessionID: nil
            )
        }
    }

    private func enqueuePlaybackReport(
        _ operation: @escaping @MainActor @Sendable (any MusicPlaybackServicing) async -> Void
    ) {
        let previous = pendingPlaybackReport
        let service = self.service
        pendingPlaybackReport = Task {
            await previous?.value
            await operation(service)
        }
    }

    private var reportingTrackDuration: Double? {
        let duration = resolvedTrackDuration > 0
            ? resolvedTrackDuration
            : currentTrack?.duration ?? 0
        return duration.isFinite && duration > 0 ? duration : nil
    }
}
