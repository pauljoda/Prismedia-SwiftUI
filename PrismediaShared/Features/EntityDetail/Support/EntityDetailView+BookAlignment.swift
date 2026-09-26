import Foundation

extension EntityDetailView {
    // MARK: - Actions - Chapter Mapping Editor

    var supportsBookChapterMapping: Bool {
        guard let detail = currentDetail else { return false }
        return bookChapterMappingEditorPresentation(for: detail) != nil
    }

    /// The chapter-mapping editor in the connected server's shape. There is no editor while the
    /// server's progress contract is undecided or its alignment has not loaded.
    func bookChapterMappingEditorPresentation(
        for detail: EntityDetail
    ) -> BookChapterMappingEditorPresentation? {
        #if os(iOS) || os(macOS)
            guard dependencies.alignmentService != nil,
                let tracks = audiobookProjection?.tracks,
                !tracks.isEmpty
            else { return nil }
            switch bookAlignmentState.contract {
            case .legacyCursor:
                return legacyBookChapterMappingEditorPresentation(for: detail, audioTracks: tracks)
            case .serverAlignment:
                guard let alignment = bookAlignmentState.alignment else { return nil }
                // The server's rows are the editor's source: readable chapters in display order,
                // audio windows with their provenance, and each repeated audio window only once.
                let presentation = BookChapterMappingEditorPresentation(
                    alignment: alignment,
                    audioTracks: tracks,
                    loadErrorMessage: bookAlignmentState.errorMessage
                )
                return presentation.readableChapters.isEmpty ? nil : presentation
            case nil:
                return nil
            }
        #else
            return nil
        #endif
    }

    // MARK: - Actions - Loading

    /// Loads the Book's alignment in the connected server's shape: the server projection on 3.8+
    /// servers, the chapter map on older ones. A failed version read leaves the contract undecided
    /// and the page in its error state; a failed reload keeps the last loaded alignment.
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

    /// Reads the alignment first when the server's progress contract is still undecided (the
    /// version read failed or was cancelled), so no action proceeds in a guessed contract.
    /// - Returns: Whether a contract is known for `detail` afterwards.
    func decideBookAlignmentContractIfNeeded(for detail: EntityDetail) async -> Bool {
        if bookAlignmentState.contract == nil {
            await loadBookAlignment(for: detail)
        }
        return currentDetail?.id == detail.id && bookAlignmentState.contract != nil
    }

    /// Retries what the chapter rows depend on: the readable contents when they failed, and the
    /// alignment when it failed or its contract is still undecided.
    func retryBookChapterRows(for detail: EntityDetail) async {
        if bookChaptersErrorMessage != nil {
            await loadBookChapters(for: detail)
        }
        if bookAlignmentState.errorMessage != nil || bookAlignmentState.contract == nil {
            await loadBookAlignment(for: detail)
        }
    }

    // MARK: - Actions - Saving

    /// Saves the user's manual chapter mappings and returns the persisted map, including the
    /// server's refreshed automatic rows. Nothing is sent while the progress contract is undecided.
    func saveBookChapterMappings(
        _ mappings: [BookChapterAudioMapping],
        for detail: EntityDetail
    ) async throws -> [BookChapterAudioMapping] {
        guard let alignmentService = dependencies.alignmentService,
            let contract = bookAlignmentState.contract
        else { return [] }
        let saved = try await BookAlignmentLoader(service: alignmentService).save(
            bookID: detail.id,
            mappings: mappings,
            contract: contract
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
