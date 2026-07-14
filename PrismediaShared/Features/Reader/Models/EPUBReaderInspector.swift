import Foundation

enum EPUBReaderInspector: String, Identifiable {
    case contents
    case bookmarks

    var id: Self { self }
}
