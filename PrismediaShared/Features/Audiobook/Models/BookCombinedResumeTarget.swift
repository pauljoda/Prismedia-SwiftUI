import Foundation

struct BookCombinedResumeTarget: Equatable, Sendable {
    let readingTarget: BookCombinedReadingTarget
    let audioTrackID: UUID
    let audioStartSeconds: Double
}
