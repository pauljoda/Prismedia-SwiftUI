import Foundation

enum PDFReaderError: Error, Equatable, LocalizedError, Sendable {
    case invalidDocument

    var errorDescription: String? {
        "This PDF is damaged, encrypted, or otherwise unreadable."
    }
}
