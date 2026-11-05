import Foundation

/// How many pages a PDF shows at once. Automatic reads like a book: two pages side by
/// side when the reader is wider than it is tall, one page when it is taller.
public enum PDFReaderPageLayout: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case single
    case double

    public var id: Self { self }

    var label: String {
        switch self {
        case .automatic: "Automatic"
        case .single: "One Page"
        case .double: "Two Pages"
        }
    }

    var systemImage: String {
        switch self {
        case .automatic: "book"
        case .single: "rectangle.portrait"
        case .double: "rectangle.split.2x1"
        }
    }

    /// Whether two pages sit side by side in a reader of the given shape.
    public func showsSpread(isWide: Bool) -> Bool {
        switch self {
        case .automatic: isWide
        case .single: false
        case .double: true
        }
    }
}
