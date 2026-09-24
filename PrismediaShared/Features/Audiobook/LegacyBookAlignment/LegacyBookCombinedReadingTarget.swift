import Foundation

/// Reading side of a client-aligned resume target, for servers before 3.8.
enum LegacyBookCombinedReadingTarget: Equatable, Sendable {
    case savedLocation(String?)
    case chapter(location: String, progression: Double)
    case entityChapter(id: UUID)

    /// The reader destination; a saved position without a locator resumes the reader itself.
    var destination: BookReadingDestination? {
        switch self {
        case .savedLocation(let location):
            location.map(BookReadingDestination.epubLocator)
        case .chapter(let location, let progression):
            .epubChapter(BookReaderLocationTarget(location: location, progression: progression))
        case .entityChapter(let chapterID):
            .chapterPage(chapterID: chapterID, pageIndex: 0)
        }
    }
}
