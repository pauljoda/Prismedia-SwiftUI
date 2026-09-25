import Foundation

/// View-owned Book alignment: the connected server's progress contract with its alignment
/// projection (3.8+) or an older server's chapter map, guarded against responses from a previous
/// Book. The contract stays undecided while the server version cannot be read, and a failed
/// reload keeps the last good content beside its error.
struct BookAlignmentState: Equatable, Sendable {
    // MARK: - Variables

    /// The server-owned alignment projection, on servers that serve it.
    private(set) var alignment: BookAlignmentResponse?
    /// An older server's explicit chapter map (before 3.8).
    private(set) var legacyMappings: [BookChapterAudioMapping] = []
    /// An older server's audio chapter catalog (before 3.8).
    private(set) var legacyAudioChapters: [BookAudioChapter] = []
    /// How the connected server keeps Book progress; nil until its version has been read.
    private(set) var contract: BookProgressContract?
    private(set) var errorMessage: String?

    private var bookID: UUID?
    private var generation = 0

    /// Whether the server owns this Book's alignment, resume targets, and modality checkpoints.
    var usesServerAlignment: Bool {
        contract == .serverAlignment
    }

    /// Whether an older server (before 3.8) keeps this Book's chapter map and one shared cursor.
    /// False while the contract is undecided, so an unreadable server version never reads as old.
    var usesLegacyAlignment: Bool {
        contract == .legacyCursor
    }

    // MARK: - Actions - Loading

    mutating func beginLoad(bookID: UUID) -> Int {
        generation += 1
        if self.bookID != bookID {
            clearContent()
            contract = nil
        }
        self.bookID = bookID
        errorMessage = nil
        return generation
    }

    /// Applies a load result. A failure keeps the content and contract of the last successful
    /// load; it decides the contract only when none was known and the failure names one.
    mutating func finishLoad(
        _ result: Result<BookAlignmentSnapshot, any Error>,
        bookID: UUID,
        generation requestGeneration: Int
    ) {
        guard self.bookID == bookID, generation == requestGeneration else { return }
        switch result {
        case .success(let snapshot):
            apply(snapshot)
        case .failure(let error):
            if contract == nil, let failure = error as? BookAlignmentLoadError {
                contract = failure.contract
            }
            errorMessage = error.localizedDescription
        }
    }

    /// Applies a saved alignment for the current Book; returns false for a previous Book.
    @discardableResult
    mutating func replace(_ snapshot: BookAlignmentSnapshot, bookID: UUID) -> Bool {
        guard self.bookID == bookID else { return false }
        generation += 1
        apply(snapshot)
        return true
    }

    mutating func dismissError() {
        errorMessage = nil
    }

    mutating func reset() {
        generation += 1
        bookID = nil
        contract = nil
        clearContent()
        errorMessage = nil
    }

    private mutating func apply(_ snapshot: BookAlignmentSnapshot) {
        contract = snapshot.contract
        errorMessage = nil
        switch snapshot {
        case .server(let alignment):
            self.alignment = alignment
            legacyMappings = []
            legacyAudioChapters = []
        case .legacy(let response):
            alignment = nil
            legacyMappings = response.mappings
            legacyAudioChapters = response.audioChapters
        }
    }

    private mutating func clearContent() {
        alignment = nil
        legacyMappings = []
        legacyAudioChapters = []
    }
}
