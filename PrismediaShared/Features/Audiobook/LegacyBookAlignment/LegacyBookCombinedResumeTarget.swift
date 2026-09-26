import Foundation

/// A client-aligned combined reading and listening start, for servers before 3.8.
struct LegacyBookCombinedResumeTarget: Equatable, Sendable {
    let readingTarget: LegacyBookCombinedReadingTarget
    let audioTrackID: UUID
    let audioStartSeconds: Double
}
