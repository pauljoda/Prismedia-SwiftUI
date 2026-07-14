import Foundation

public struct BookReaderPosition: Hashable, Sendable {
    public let chapterID: UUID
    public let pageIndex: Int
    public let pageCount: Int
}
