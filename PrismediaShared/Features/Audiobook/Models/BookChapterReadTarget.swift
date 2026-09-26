import Foundation

enum BookChapterReadTarget: Equatable, Hashable, Sendable {
    case epub(location: String)
    case entityChapter(id: UUID)

    /// The start of this chapter as a reader destination.
    var chapterStart: BookReadingDestination {
        switch self {
        case .epub(let location):
            .epubChapter(BookReaderLocationTarget(location: location, progression: 0))
        case .entityChapter(let chapterID):
            .chapterPage(chapterID: chapterID, pageIndex: 0)
        }
    }
}
