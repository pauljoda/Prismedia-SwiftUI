import Foundation

enum PDFReaderFitMode: String, CaseIterable, Identifiable, Sendable {
    case page
    case width

    var id: Self { self }

    var label: String {
        switch self {
        case .page: "Fit Page"
        case .width: "Fit Width"
        }
    }

    var systemImage: String {
        switch self {
        case .page: "rectangle.inset.filled"
        case .width: "arrow.left.and.right"
        }
    }
}
