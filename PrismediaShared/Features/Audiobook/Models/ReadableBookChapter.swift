import Foundation

struct ReadableBookChapter: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let order: Int
    let depth: Int
    let target: BookChapterReadTarget
    let startFraction: Double?
    let endFraction: Double?
    let pageCount: Int?

    init(
        id: String,
        title: String,
        order: Int,
        depth: Int,
        target: BookChapterReadTarget,
        startFraction: Double? = nil,
        endFraction: Double? = nil,
        pageCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.depth = depth
        self.target = target
        self.startFraction = startFraction
        self.endFraction = endFraction
        self.pageCount = pageCount
    }
}

extension ReadableBookChapter {
    /// The readable chapter of a server alignment row, at its display position `order`.
    init(window: BookReadableChapterWindow, order: Int) {
        self.init(
            id: window.chapterKey,
            title: window.title,
            order: order,
            depth: window.depth,
            target: window.readTarget,
            startFraction: window.startFraction,
            endFraction: window.endFraction,
            pageCount: window.pageCount
        )
    }
}
