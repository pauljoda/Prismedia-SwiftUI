import Foundation

extension EntityDetailView {
    var supportsBookChapterMapping: Bool {
        #if os(iOS) || os(macOS)
            currentDetail?.kind == .book
                && dependencies.chapterMappingService != nil
                && !readableBookChapters.isEmpty
                && audiobookProjection?.tracks.isEmpty == false
        #else
            false
        #endif
    }

    func bookChapterMappingEditorPresentation(
        for detail: EntityDetail
    ) -> BookChapterMappingEditorPresentation? {
        #if os(iOS) || os(macOS)
            guard detail.kind == .book,
                dependencies.chapterMappingService != nil,
                !readableBookChapters.isEmpty,
                let tracks = audiobookProjection?.tracks,
                !tracks.isEmpty
            else { return nil }
            return BookChapterMappingEditorPresentation(
                readableChapters: readableBookChapters,
                audioTracks: tracks,
                mappings: bookChapterMappingState.mappings,
                loadErrorMessage: bookChapterMappingState.errorMessage
            )
        #else
            return nil
        #endif
    }

    func loadBookChapterMappings(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard detail.kind == .book,
                let mappingService = dependencies.chapterMappingService
            else {
                bookChapterMappingState.reset()
                refreshBookChapterMappings(for: detail)
                return
            }

            let generation = bookChapterMappingState.beginLoad(bookID: detail.id)
            do {
                let mappings = try await mappingService.loadBookChapterMappings(bookID: detail.id)
                guard currentDetail?.id == detail.id else { return }
                bookChapterMappingState.finishLoad(
                    .success(mappings),
                    bookID: detail.id,
                    generation: generation
                )
            } catch is CancellationError {
                return
            } catch {
                guard currentDetail?.id == detail.id else { return }
                bookChapterMappingState.finishLoad(
                    .failure(error),
                    bookID: detail.id,
                    generation: generation
                )
            }
            refreshBookChapterMappings(for: detail)
        #else
            bookChapterMappingState.reset()
        #endif
    }

    func saveBookChapterMappings(
        _ mappings: [BookChapterAudioMapping],
        for detail: EntityDetail
    ) async throws -> [BookChapterAudioMapping] {
        guard let mappingService = dependencies.chapterMappingService else { return [] }
        let persisted = try await mappingService.replaceBookChapterMappings(
            bookID: detail.id,
            mappings: mappings
        )
        guard currentDetail?.id == detail.id,
            bookChapterMappingState.replace(persisted, bookID: detail.id)
        else { return persisted }
        #if os(iOS) || os(macOS)
            refreshBookChapterMappings(for: detail)
        #endif
        return persisted
    }
}
