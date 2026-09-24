import Foundation

/// Loads the server-owned Book alignment and saves chapter mappings. It extends the legacy
/// chapter-mapping routes, which older servers still need, with the version lookup that decides
/// between them.
public protocol BookAlignmentServicing: BookChapterMappingServicing {
    /// The connected server's build version, or nil when it reports none (servers before 3.8).
    func loadServerVersion() async throws -> PrismediaServerVersion?

    /// Loads the Book's alignment rows, coverage, and the current user's resume targets.
    func loadBookAlignment(bookID: UUID) async throws -> BookAlignmentResponse

    /// Replaces the Book's manual chapter mappings and returns the refreshed alignment.
    func saveBookChapterMappings(
        bookID: UUID,
        mappings: [BookChapterAudioMapping]
    ) async throws -> BookAlignmentResponse
}
