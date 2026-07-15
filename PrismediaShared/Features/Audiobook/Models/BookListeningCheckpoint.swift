import Foundation

struct BookListeningCheckpoint: Equatable, Sendable {
    let trackID: UUID
    let trackOffsetSeconds: Double
    let publicationProgression: Double

    init(trackID: UUID, trackOffsetSeconds: Double, publicationProgression: Double) {
        self.trackID = trackID
        self.trackOffsetSeconds = max(0, trackOffsetSeconds)
        self.publicationProgression = min(max(0, publicationProgression), 1)
    }
}
