import Foundation

/// View-owned persisted alignment state, guarded against responses from a previous Book.
struct BookChapterMappingState: Equatable, Sendable {
    private(set) var mappings: [BookChapterAudioMapping] = []
    private(set) var audioChapters: [BookAudioChapter] = []
    private(set) var errorMessage: String?

    private var bookID: UUID?
    private var generation = 0

    mutating func beginLoad(bookID: UUID) -> Int {
        generation += 1
        if self.bookID != bookID {
            mappings = []
            audioChapters = []
        }
        self.bookID = bookID
        errorMessage = nil
        return generation
    }

    mutating func finishLoad(
        _ result: Result<BookChapterMappingsResponse, Error>,
        bookID: UUID,
        generation requestGeneration: Int
    ) {
        guard self.bookID == bookID, generation == requestGeneration else { return }
        switch result {
        case .success(let response):
            mappings = response.mappings
            audioChapters = response.audioChapters
            errorMessage = nil
        case .failure(let error):
            mappings = []
            audioChapters = []
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    mutating func replace(
        _ response: BookChapterMappingsResponse,
        bookID: UUID
    ) -> Bool {
        guard self.bookID == bookID else { return false }
        generation += 1
        mappings = response.mappings
        audioChapters = response.audioChapters
        errorMessage = nil
        return true
    }

    mutating func reset() {
        generation += 1
        bookID = nil
        mappings = []
        audioChapters = []
        errorMessage = nil
    }
}
