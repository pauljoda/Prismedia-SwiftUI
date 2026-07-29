import Foundation

struct BookResumeChapterSelection: Equatable, Sendable {
    let bookID: UUID
    let chapterID: String
    let readingTarget: BookReaderLocationTarget?
}
