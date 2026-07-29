import Foundation

struct EPUBChapterContents: Equatable, Sendable {
    let chapters: [ReadableBookChapter]
    let currentChapterID: String?
    let resumeTarget: BookReaderLocationTarget?

    init(
        chapters: [ReadableBookChapter],
        currentChapterID: String?,
        resumeTarget: BookReaderLocationTarget? = nil
    ) {
        self.chapters = chapters
        self.currentChapterID = currentChapterID
        self.resumeTarget = resumeTarget
    }
}
