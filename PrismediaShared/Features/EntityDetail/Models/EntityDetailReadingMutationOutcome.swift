import Foundation

enum EntityDetailReadingMutationOutcome: Hashable, Sendable {
    case content(BookReaderManifest)
    case singleFile(EntityDetail)
    case failure(String)
    case cancelled
    case unavailable
}
