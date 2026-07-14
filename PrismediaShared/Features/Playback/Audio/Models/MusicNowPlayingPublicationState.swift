import Foundation

struct MusicNowPlayingPublicationState {
    private var publishedTrackID: UUID?

    mutating func beginPublishing(trackID: UUID) -> Bool {
        guard publishedTrackID != trackID else { return false }
        publishedTrackID = trackID
        return true
    }

    mutating func clear() {
        publishedTrackID = nil
    }
}
