import Foundation

extension PrismediaAPIClient: BookAlignmentServicing {
    public func loadServerVersion() async throws -> PrismediaServerVersion? {
        if let resolution = serverVersionCache.resolution { return resolution }
        let version = try await health().serverVersion
        serverVersionCache.resolve(version)
        return version
    }

    public func loadBookAlignment(bookID: UUID) async throws -> BookAlignmentResponse {
        try await send(
            BookAlignmentResponse.self,
            path: "/api/books/\(bookID.uuidString.lowercased())/alignment"
        )
    }

    public func saveBookChapterMappings(
        bookID: UUID,
        mappings: [BookChapterAudioMapping]
    ) async throws -> BookAlignmentResponse {
        try await send(
            BookAlignmentResponse.self,
            path: "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings",
            method: "PUT",
            body: ReplaceBookChapterMappingsRequest(mappings: mappings)
        )
    }
}
