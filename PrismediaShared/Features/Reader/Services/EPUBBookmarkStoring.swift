import Foundation

public protocol EPUBBookmarkStoring: Sendable {
    func load(bookID: UUID) -> EPUBBookmarksState
    func save(_ state: EPUBBookmarksState, bookID: UUID)
}
