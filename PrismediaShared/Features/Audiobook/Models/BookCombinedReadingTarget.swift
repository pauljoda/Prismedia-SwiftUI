import Foundation

enum BookCombinedReadingTarget: Equatable, Sendable {
    case savedLocation(String?)
    case chapter(location: String, progression: Double)
    case entityChapter(id: UUID)
}
