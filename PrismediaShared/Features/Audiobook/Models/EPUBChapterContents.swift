import Foundation

struct EPUBChapterContents: Equatable, Sendable {
    let chapters: [ReadableBookChapter]
    let currentChapterID: String?
}
