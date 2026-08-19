import Foundation

/// Loads and replaces the explicit audiobook alignment owned by a Book.
public protocol BookChapterMappingServicing: Sendable {
    func loadBookChapterMappings(bookID: UUID) async throws -> [BookChapterAudioMapping]

    func replaceBookChapterMappings(
        bookID: UUID,
        mappings: [BookChapterAudioMapping]
    ) async throws -> [BookChapterAudioMapping]
}
