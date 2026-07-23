import Foundation

/// Deterministic queue policy, independent from any platform playback engine.
public struct MusicQueue: Equatable, Sendable {
    private static let historyLimit = 100

    public private(set) var tracks: [MusicTrack]
    public private(set) var position: Int
    public private(set) var repeatMode: MusicRepeatMode = .off
    public private(set) var isShuffled = false
    public private(set) var history: [MusicQueueHistoryEntry] = []

    private var order: [Int]
    private var nextHistorySequence: UInt64 = 0

    public init(
        tracks: [MusicTrack],
        startingAt trackID: UUID? = nil,
        history: [MusicQueueHistoryEntry] = []
    ) {
        let playableTracks = tracks.filter(\.isPlayable)
        self.tracks = playableTracks
        order = Array(playableTracks.indices)
        position =
            trackID
            .flatMap { id in playableTracks.firstIndex { $0.id == id } }
            ?? (playableTracks.isEmpty ? -1 : 0)
        let playableHistory = history.filter { $0.track.isPlayable }
        self.history = Array(playableHistory.suffix(Self.historyLimit))
        nextHistorySequence = (playableHistory.map(\.sequence).max() ?? 0) + (playableHistory.isEmpty ? 0 : 1)
    }

    public init(restoration: MusicPlaybackRestoration) {
        let restoredTracks = restoration.tracks.filter(\.isPlayable)
        var indexesByID: [UUID: Int] = [:]
        for (index, track) in restoredTracks.enumerated() where indexesByID[track.id] == nil {
            indexesByID[track.id] = index
        }
        var seen = Set<Int>()
        var restoredOrder: [Int]
        if restoration.context?.isAudiobook == true {
            restoredOrder = Array(restoredTracks.indices)
        } else {
            restoredOrder = restoration.orderedTrackIDs.compactMap { id in
                guard let index = indexesByID[id], seen.insert(index).inserted else { return nil }
                return index
            }
            restoredOrder += restoredTracks.indices.filter { seen.insert($0).inserted }
        }
        let restoredPosition =
            restoration.currentTrackID
            .flatMap { currentID in
                restoredOrder.firstIndex { restoredTracks[$0].id == currentID }
            }
            ?? (restoredOrder.isEmpty ? -1 : 0)
        tracks = restoredTracks
        order = restoredOrder
        position = restoredPosition
        repeatMode = restoration.repeatMode
        isShuffled = restoration.context?.isAudiobook == true ? false : restoration.isShuffled
        history = Array((restoration.history ?? []).filter { $0.track.isPlayable }.suffix(Self.historyLimit))
        nextHistorySequence = (history.map(\.sequence).max() ?? 0) + (history.isEmpty ? 0 : 1)
    }

    public var currentTrack: MusicTrack? {
        guard order.indices.contains(position) else { return nil }
        return tracks[order[position]]
    }

    /// Tracks in the same order playback will visit them.
    public var orderedTracks: [MusicTrack] {
        order.map { tracks[$0] }
    }

    public var upNextTracks: [MusicTrack] {
        guard order.indices.contains(position) else { return [] }
        return order.dropFirst(position + 1).map { tracks[$0] }
    }

    public func upNextTracks(limit: Int) -> [MusicTrack] {
        guard limit > 0, order.indices.contains(position) else { return [] }
        return order.dropFirst(position + 1).prefix(limit).map { tracks[$0] }
    }

    public var canGoNext: Bool {
        guard currentTrack != nil else { return false }
        return position < order.count - 1 || repeatMode != .off
    }

    public var canGoPrevious: Bool {
        guard currentTrack != nil else { return false }
        return !history.isEmpty || position > 0 || repeatMode != .off
    }

    public mutating func setRepeatMode(_ mode: MusicRepeatMode) {
        repeatMode = mode
    }

    public mutating func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    @discardableResult
    public mutating func advance(reason: MusicQueueAdvanceReason) -> MusicTrack? {
        guard currentTrack != nil else { return nil }

        if reason == .playbackEnded, repeatMode == .one {
            return currentTrack
        }

        if reason == .user {
            promoteRepeatOneToAll()
        }

        if position < order.count - 1 {
            appendCurrentTrackToHistory()
            position += 1
            return currentTrack
        }

        guard repeatMode == .all else { return nil }
        appendCurrentTrackToHistory()
        position = 0
        return currentTrack
    }

    @discardableResult
    public mutating func movePrevious() -> MusicTrack? {
        guard currentTrack != nil else { return nil }
        promoteRepeatOneToAll()

        if let previous = history.popLast(),
            let previousTrackIndex = tracks.firstIndex(where: { $0.id == previous.track.id })
        {
            if let previousPosition = order.firstIndex(of: previousTrackIndex) {
                position = previousPosition
            } else {
                order.insert(previousTrackIndex, at: 0)
                position = 0
            }
            return currentTrack
        }

        if position > 0 {
            position -= 1
            return currentTrack
        }

        guard repeatMode == .all else { return nil }
        position = order.count - 1
        return currentTrack
    }

    public mutating func setShuffled(_ enabled: Bool) {
        var generator = SystemRandomNumberGenerator()
        setShuffled(enabled, using: &generator)
    }

    public mutating func shuffleAll() {
        var generator = SystemRandomNumberGenerator()
        shuffleAll(using: &generator)
    }

    public mutating func shuffleAll<R: RandomNumberGenerator>(
        using generator: inout R
    ) {
        order = Array(tracks.indices)
        order.shuffle(using: &generator)
        position = order.isEmpty ? -1 : 0
        isShuffled = true
    }

    public mutating func setShuffled<R: RandomNumberGenerator>(
        _ enabled: Bool,
        using generator: inout R
    ) {
        guard enabled != isShuffled, let currentTrack else { return }
        guard let currentNaturalIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }) else { return }

        if enabled {
            let playedTrackIDs = Set(history.map(\.track.id))
            var remaining = tracks.indices.filter {
                $0 != currentNaturalIndex && !playedTrackIDs.contains(tracks[$0].id)
            }
            remaining.shuffle(using: &generator)
            order = [currentNaturalIndex] + remaining
            position = 0
        } else {
            order = [currentNaturalIndex] + tracks.indices.filter { $0 > currentNaturalIndex }
            position = 0
        }

        isShuffled = enabled
    }

    public mutating func appendUpcomingTracks(_ newTracks: [MusicTrack]) {
        var existingIDs = Set(tracks.map(\.id))
        let uniqueTracks = newTracks.filter { $0.isPlayable && existingIDs.insert($0.id).inserted }
        guard !uniqueTracks.isEmpty else { return }
        promoteRepeatOneToAll()

        let firstNewIndex = tracks.count
        tracks += uniqueTracks
        order += firstNewIndex..<tracks.count
    }

    public mutating func recordCurrentTrackInHistory() {
        appendCurrentTrackToHistory()
    }

    public mutating func clearHistory() {
        history.removeAll()
    }

    @discardableResult
    public mutating func moveToUpcomingTrack(id trackID: UUID) -> MusicTrack? {
        guard
            let destination = order.indices.first(where: { index in
                index > position && tracks[order[index]].id == trackID
            })
        else { return nil }

        promoteRepeatOneToAll()
        appendCurrentTrackToHistory()
        position = destination
        return currentTrack
    }

    @discardableResult
    public mutating func moveUpcomingTrack(id trackID: UUID, before destinationID: UUID) -> Bool {
        guard trackID != destinationID,
            let source = order.indices.first(where: { index in
                index > position && tracks[order[index]].id == trackID
            }),
            order.indices.contains(where: { index in
                index > position && tracks[order[index]].id == destinationID
            })
        else { return false }

        let movedTrackIndex = order.remove(at: source)
        guard
            let destination = order.indices.first(where: { index in
                index > position && tracks[order[index]].id == destinationID
            })
        else {
            order.insert(movedTrackIndex, at: source)
            return false
        }
        order.insert(movedTrackIndex, at: destination)
        return true
    }

    @discardableResult
    public mutating func moveUpcomingTrack(id trackID: UUID, after destinationID: UUID) -> Bool {
        guard trackID != destinationID,
            let source = order.indices.first(where: { index in
                index > position && tracks[order[index]].id == trackID
            }),
            order.indices.contains(where: { index in
                index > position && tracks[order[index]].id == destinationID
            })
        else { return false }

        let movedTrackIndex = order.remove(at: source)
        guard
            let destination = order.indices.first(where: { index in
                index > position && tracks[order[index]].id == destinationID
            })
        else {
            order.insert(movedTrackIndex, at: source)
            return false
        }
        order.insert(movedTrackIndex, at: destination + 1)
        return true
    }

    private mutating func appendCurrentTrackToHistory() {
        guard let currentTrack else { return }
        history.append(
            MusicQueueHistoryEntry(
                sequence: nextHistorySequence,
                track: currentTrack
            )
        )
        if history.count > Self.historyLimit {
            history.removeFirst(history.count - Self.historyLimit)
        }
        nextHistorySequence += 1
    }

    private mutating func promoteRepeatOneToAll() {
        guard repeatMode == .one else { return }
        repeatMode = .all
    }
}
