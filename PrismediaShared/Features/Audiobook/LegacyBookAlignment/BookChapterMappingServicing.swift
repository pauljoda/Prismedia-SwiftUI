import Foundation

/// Loads and replaces an older server's persisted chapter map (`/chapter-mappings` before 3.8).
/// Servers from 3.8 serve the alignment projection through `BookAlignmentServicing` instead.
public protocol BookChapterMappingServicing: Sendable {
    func loadBookChapterMappings(bookID: UUID) async throws -> BookChapterMappingsResponse

    func replaceBookChapterMappings(
        bookID: UUID,
        mappings: [BookChapterAudioMapping]
    ) async throws -> BookChapterMappingsResponse
}
