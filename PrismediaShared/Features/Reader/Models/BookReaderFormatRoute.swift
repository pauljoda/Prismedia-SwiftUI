import Foundation

public enum BookReaderFormatRoute: Equatable, Sendable {
    case unavailable
    case pdf
    case epub
    case unsupported(BookFormat)
}
