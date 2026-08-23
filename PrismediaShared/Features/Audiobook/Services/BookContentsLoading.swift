import Foundation

/// Loads the server-projected readable chapter metadata for a Book.
public protocol BookContentsLoading: Sendable {
    func loadBookContents(bookID: UUID) async throws -> [BookContentsEntry]
}
