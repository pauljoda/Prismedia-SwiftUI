import Foundation

extension PrismediaAPIClient: BookChapterMappingServicing {
    public func loadBookChapterMappings(bookID: UUID) async throws -> [BookChapterAudioMapping] {
        let response = try await send(
            BookChapterMappingsResponse.self,
            path: "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings"
        )
        return response.mappings
    }

    public func replaceBookChapterMappings(
        bookID: UUID,
        mappings: [BookChapterAudioMapping]
    ) async throws -> [BookChapterAudioMapping] {
        let response = try await send(
            BookChapterMappingsResponse.self,
            path: "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings",
            method: "PUT",
            body: ReplaceBookChapterMappingsRequest(mappings: mappings)
        )
        return response.mappings
    }
}
