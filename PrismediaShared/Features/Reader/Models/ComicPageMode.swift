import Foundation

public enum ComicPageMode: Hashable, Sendable {
    /// Reads like a book: two pages side by side when the reader is wider than
    /// it is tall, one page when it is taller.
    case automatic
    case single
    case double
}
