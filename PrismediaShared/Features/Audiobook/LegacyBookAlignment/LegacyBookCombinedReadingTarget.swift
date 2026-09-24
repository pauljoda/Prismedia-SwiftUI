import Foundation

/// Reading side of a client-aligned resume target, for servers before 3.8.
enum LegacyBookCombinedReadingTarget: Equatable, Sendable {
    case savedLocation(String?)
    case chapter(location: String, progression: Double)
    case entityChapter(id: UUID)
}
