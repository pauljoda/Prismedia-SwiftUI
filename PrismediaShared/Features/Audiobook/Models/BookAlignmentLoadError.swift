import Foundation

/// A failed alignment load, carrying the progress contract when it was decided before the failure.
struct BookAlignmentLoadError: LocalizedError {
    // MARK: - Variables

    /// The server's progress contract, or nil when the server version could not be read.
    let contract: BookProgressContract?
    let underlying: any Error

    var errorDescription: String? {
        underlying.localizedDescription
    }
}
