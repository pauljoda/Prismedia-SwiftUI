import Foundation

public struct BookChapterSummary: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let sortOrder: Int
    public let pageCount: Int

    public init(id: UUID, title: String, sortOrder: Int, pageCount: Int) {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
        self.pageCount = pageCount
    }
}
