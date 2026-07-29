import Foundation

enum BookChapterReadTarget: Equatable, Hashable, Sendable {
    case epub(location: String)
    case entityChapter(id: UUID)
}
