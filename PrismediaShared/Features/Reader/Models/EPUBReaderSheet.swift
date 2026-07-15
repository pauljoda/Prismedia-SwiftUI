import Foundation

enum EPUBReaderSheet: String, Hashable, Identifiable {
    case navigation
    case contents
    case search
    case bookmarks
    case settings
    case audiobook

    var id: Self { self }
}
