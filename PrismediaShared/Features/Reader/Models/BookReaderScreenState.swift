import Foundation

public enum BookReaderScreenState: Sendable {
    case loading
    case content(BookReaderManifest)
    case failure(String)
}
