enum MusicQueueArtworkWindow {
    static let lookAheadCount = 10

    static func tracks(in queue: MusicQueue) -> [MusicTrack] {
        guard let currentTrack = queue.currentTrack else { return [] }
        return [currentTrack] + queue.upNextTracks.prefix(lookAheadCount)
    }
}
