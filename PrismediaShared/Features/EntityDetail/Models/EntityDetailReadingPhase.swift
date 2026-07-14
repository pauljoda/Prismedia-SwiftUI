import Foundation

enum EntityDetailReadingPhase: Hashable, Sendable {
    case idle
    case loading
    case content(BookReaderManifest)
    case singleFile(EntityDetail)
    case failure(String)
}
