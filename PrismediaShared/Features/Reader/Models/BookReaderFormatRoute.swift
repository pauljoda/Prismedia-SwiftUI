import Foundation

public enum BookReaderFormatRoute: Equatable, Sendable {
    case unavailable
    case comic
    case pdf
    case epub
    case unsupported(BookFormat)
}
