import Foundation

public struct MusicPlaybackRestoration: Codable, Equatable, Sendable {
    public let tracks: [MusicTrack]
    public let orderedTrackIDs: [UUID]
    public let currentTrackID: UUID?
    public let repeatMode: MusicRepeatMode
    public let isShuffled: Bool
    public let elapsedTime: Double
    public let context: MusicPlaybackContext?
    public let audiobookCompleted: Bool?
    public let history: [MusicQueueHistoryEntry]?

    public init(
        tracks: [MusicTrack],
        orderedTrackIDs: [UUID],
        currentTrackID: UUID?,
        repeatMode: MusicRepeatMode,
        isShuffled: Bool,
        elapsedTime: Double,
        context: MusicPlaybackContext? = nil,
        audiobookCompleted: Bool? = nil,
        history: [MusicQueueHistoryEntry]? = nil
    ) {
        self.tracks = tracks
        self.orderedTrackIDs = orderedTrackIDs
        self.currentTrackID = currentTrackID
        self.repeatMode = repeatMode
        self.isShuffled = isShuffled
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        self.context = context
        self.audiobookCompleted = audiobookCompleted
        self.history = history
    }

    public init(
        queue: MusicQueue,
        elapsedTime: Double,
        context: MusicPlaybackContext? = nil,
        audiobookCompleted: Bool? = nil
    ) {
        self.init(
            tracks: queue.tracks,
            orderedTrackIDs: queue.orderedTracks.map(\.id),
            currentTrackID: queue.currentTrack?.id,
            repeatMode: queue.repeatMode,
            isShuffled: queue.isShuffled,
            elapsedTime: elapsedTime,
            context: context,
            audiobookCompleted: audiobookCompleted,
            history: queue.history
        )
    }
}
