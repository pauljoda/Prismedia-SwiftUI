import Foundation

struct BookReadingCheckpoint: Equatable, Sendable {
    let chapterLocation: String
    let chapterProgression: Double
    let publicationProgression: Double

    init(
        chapterLocation: String,
        chapterProgression: Double,
        publicationProgression: Double
    ) {
        self.chapterLocation = chapterLocation
        self.chapterProgression = min(max(0, chapterProgression), 1)
        self.publicationProgression = min(max(0, publicationProgression), 1)
    }
}
