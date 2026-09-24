import Foundation

/// A loaded Book alignment in the shape the connected server provides.
enum BookAlignmentSnapshot: Equatable, Sendable {
    /// The server-owned alignment projection (3.8+).
    case server(BookAlignmentResponse)
    /// The persisted chapter map of an older server, aligned on the client.
    case legacy(BookChapterMappingsResponse)

    /// The progress contract this snapshot came from.
    var contract: BookProgressContract {
        switch self {
        case .server: .serverAlignment
        case .legacy: .legacyCursor
        }
    }
}
