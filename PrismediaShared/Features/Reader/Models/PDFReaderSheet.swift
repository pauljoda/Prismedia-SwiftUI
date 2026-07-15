import Foundation

enum PDFReaderSheet: String, Identifiable {
    case contents
    case search
    case viewOptions

    var id: Self { self }
}
