import Foundation

extension PrismediaAPIClient: BookContentsLoading {
    public func loadBookContents(bookID: UUID) async throws -> [BookContentsEntry] {
        let response = try await send(
            BookContentsResponse.self,
            path: "/api/books/\(bookID.uuidString.lowercased())/contents"
        )
        return response.items
    }
}
