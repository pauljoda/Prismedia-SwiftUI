import Foundation

struct EntityTranscriptLoadRequest: Equatable, Sendable {
    let videoID: UUID
    let trackID: String
    let generation: Int
}
