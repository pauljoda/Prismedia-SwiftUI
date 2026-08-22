import Foundation

public struct MusicPlaybackRestoration: Codable, Equatable, Sendable {
    public let tracks: [MusicTrack]
    public let orderedTrackIDs: [UUID]
    public let currentTrackID: UUID?
    public let repeatMode: MusicRepeatMode
    public let isShuffled: Bool
    public let elapsedTime: Double
    public let context: MusicPlaybackContext?
    public let mappedProgressCompleted: Bool?
    public let history: [MusicQueueHistoryEntry]?

    public init(
        tracks: [MusicTrack],
        orderedTrackIDs: [UUID],
        currentTrackID: UUID?,
        repeatMode: MusicRepeatMode,
        isShuffled: Bool,
        elapsedTime: Double,
        context: MusicPlaybackContext? = nil,
        mappedProgressCompleted: Bool? = nil,
        history: [MusicQueueHistoryEntry]? = nil
    ) {
        self.tracks = tracks
        self.orderedTrackIDs = orderedTrackIDs
        self.currentTrackID = currentTrackID
        self.repeatMode = repeatMode
        self.isShuffled = isShuffled
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        self.context = context
        self.mappedProgressCompleted = mappedProgressCompleted
        self.history = history
    }

    public init(
        queue: MusicQueue,
        elapsedTime: Double,
        context: MusicPlaybackContext? = nil,
        mappedProgressCompleted: Bool? = nil
    ) {
        self.init(
            tracks: queue.tracks,
            orderedTrackIDs: queue.orderedTracks.map(\.id),
            currentTrackID: queue.currentTrack?.id,
            repeatMode: queue.repeatMode,
            isShuffled: queue.isShuffled,
            elapsedTime: elapsedTime,
            context: context,
            mappedProgressCompleted: mappedProgressCompleted,
            history: queue.history
        )
    }

    public func applying(_ checkpoint: MusicPlaybackProgressCheckpoint) -> Self {
        guard
            let currentTrackID = checkpoint.currentTrackID,
            tracks.contains(where: { $0.id == currentTrackID })
        else { return self }

        return Self(
            tracks: tracks,
            orderedTrackIDs: orderedTrackIDs,
            currentTrackID: currentTrackID,
            repeatMode: repeatMode,
            isShuffled: isShuffled,
            elapsedTime: checkpoint.elapsedTime,
            context: context,
            mappedProgressCompleted: checkpoint.mappedProgressCompleted,
            history: history
        )
    }

    private enum CodingKeys: String, CodingKey {
        case tracks, orderedTrackIDs, currentTrackID, repeatMode, isShuffled, elapsedTime
        case context, mappedProgressCompleted, history
        case legacyAudiobookCompleted = "audiobookCompleted"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tracks = try container.decode([MusicTrack].self, forKey: .tracks)
        orderedTrackIDs = try container.decode([UUID].self, forKey: .orderedTrackIDs)
        currentTrackID = try container.decodeIfPresent(UUID.self, forKey: .currentTrackID)
        repeatMode = try container.decode(MusicRepeatMode.self, forKey: .repeatMode)
        isShuffled = try container.decode(Bool.self, forKey: .isShuffled)
        let elapsedTime = try container.decode(Double.self, forKey: .elapsedTime)
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        context = try container.decodeIfPresent(MusicPlaybackContext.self, forKey: .context)
        mappedProgressCompleted = try container.decodeIfPresent(
            Bool.self,
            forKey: .mappedProgressCompleted
        ) ?? container.decodeIfPresent(Bool.self, forKey: .legacyAudiobookCompleted)
        history = try container.decodeIfPresent([MusicQueueHistoryEntry].self, forKey: .history)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tracks, forKey: .tracks)
        try container.encode(orderedTrackIDs, forKey: .orderedTrackIDs)
        try container.encodeIfPresent(currentTrackID, forKey: .currentTrackID)
        try container.encode(repeatMode, forKey: .repeatMode)
        try container.encode(isShuffled, forKey: .isShuffled)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(mappedProgressCompleted, forKey: .mappedProgressCompleted)
        try container.encodeIfPresent(history, forKey: .history)
    }
}
