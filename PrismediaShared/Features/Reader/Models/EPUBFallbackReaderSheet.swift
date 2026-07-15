import Foundation

enum EPUBFallbackReaderSheet: String, Identifiable {
    case chapters
    case audiobook

    var id: Self { self }
}
