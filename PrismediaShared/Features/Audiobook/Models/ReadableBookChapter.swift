import Foundation

struct ReadableBookChapter: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let order: Int
    let depth: Int
    let target: BookChapterReadTarget
}
