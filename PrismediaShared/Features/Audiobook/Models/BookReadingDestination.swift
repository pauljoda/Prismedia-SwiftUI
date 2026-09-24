import Foundation

/// Where the native reader opens a server reading target.
enum BookReadingDestination: Equatable, Sendable {
    /// A saved Readium or Prismedia locator inside the whole-book EPUB.
    case epubLocator(String)
    /// A chapter resource of the whole-book EPUB, opened at a fraction of that chapter.
    case epubChapter(BookReaderLocationTarget)
    /// A page of a paged chapter Entity.
    case chapterPage(chapterID: UUID, pageIndex: Int)
}
