public enum BookReaderCommand: Hashable, Sendable {
    case read
    case resume
    case page(Int)
}
