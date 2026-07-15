import Foundation

enum ComicReaderSheet: String, Identifiable {
    case contents
    case settings

    var id: Self { self }
}
