import Foundation

struct EPUBChapterContents: Equatable, Sendable {
    let chapters: [ReadableBookChapter]
    let currentChapterID: String?
    let progressRanges: [EPUBReadingProgressRange]

    init(
        chapters: [ReadableBookChapter],
        currentChapterID: String?,
        progressRanges: [EPUBReadingProgressRange] = []
    ) {
        self.chapters = chapters
        self.currentChapterID = currentChapterID
        self.progressRanges = progressRanges
    }
}
