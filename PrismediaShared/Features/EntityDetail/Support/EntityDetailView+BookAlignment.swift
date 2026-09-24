import Foundation

extension EntityDetailView {
    // MARK: - Actions - Chapter Mapping Editor

    var supportsBookChapterMapping: Bool {
        guard let detail = currentDetail else { return false }
        return bookChapterMappingEditorPresentation(for: detail) != nil
    }

    func bookChapterMappingEditorPresentation(
        for detail: EntityDetail
    ) -> BookChapterMappingEditorPresentation? {
        #if os(iOS) || os(macOS)
            guard dependencies.alignmentService != nil,
                let tracks = audiobookProjection?.tracks,
                !tracks.isEmpty
            else { return nil }
            guard let alignment = bookAlignmentState.alignment else {
                return legacyBookChapterMappingEditorPresentation(for: detail, audioTracks: tracks)
            }
            // The server's rows are the editor's source: readable chapters in display order, audio
            // windows with their provenance, and each repeated audio window only once.
            let presentation = BookChapterMappingEditorPresentation(
                alignment: alignment,
                audioTracks: tracks,
                loadErrorMessage: bookAlignmentState.errorMessage
            )
            return presentation.readableChapters.isEmpty ? nil : presentation
        #else
            return nil
        #endif
    }

    // MARK: - Actions - Loading

    /// Loads the Book's alignment in the connected server's shape: the server projection on 3.8+
    /// servers, the chapter map on older ones.
    func loadBookAlignment(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard detail.kind.definition?.modalities.isEmpty == false,
                let alignmentService = dependencies.alignmentService
            else {
                bookAlignmentState.reset()
                refreshBookChapterRows(for: detail)
                return
            }

            let generation = bookAlignmentState.beginLoad(bookID: detail.id)
            let result: Result<BookAlignmentSnapshot, any Error>
            do {
                result = .success(try await BookAlignmentLoader(service: alignmentService).load(bookID: detail.id))
            } catch is CancellationError {
                return
            } catch {
                result = .failure(error)
            }
            guard currentDetail?.id == detail.id else { return }
            bookAlignmentState.finishLoad(result, bookID: detail.id, generation: generation)
            refreshBookChapterRows(for: detail)
        #else
            bookAlignmentState.reset()
        #endif
    }

    // MARK: - Actions - Saving

    /// Saves the user's manual chapter mappings and returns the persisted map, including the
    /// server's refreshed automatic rows.
    func saveBookChapterMappings(
        _ mappings: [BookChapterAudioMapping],
        for detail: EntityDetail
    ) async throws -> [BookChapterAudioMapping] {
        guard let alignmentService = dependencies.alignmentService else { return [] }
        let saved = try await BookAlignmentLoader(service: alignmentService).save(
            bookID: detail.id,
            mappings: mappings,
            contract: bookAlignmentState.contract ?? .legacyCursor
        )
        guard currentDetail?.id == detail.id,
            bookAlignmentState.replace(saved, bookID: detail.id)
        else { return saved.chapterMappings }
        #if os(iOS) || os(macOS)
            refreshBookChapterRows(for: detail)
        #endif
        return saved.chapterMappings
    }
}
