import Foundation

enum PDFReaderLayoutMode: String, CaseIterable, Identifiable, Sendable {
    case paged
    case continuous

    var id: Self { self }

    var label: String {
        switch self {
        case .paged: "Paged"
        case .continuous: "Continuous"
        }
    }

    var systemImage: String {
        switch self {
        case .paged: "rectangle.portrait"
        case .continuous: "rectangle.stack"
        }
    }

    var readerMode: ReaderMode {
        switch self {
        case .paged: .paged
        case .continuous: .scrolled
        }
    }

    init(readerMode: ReaderMode?) {
        self = readerMode == .paged ? .paged : .continuous
    }
}
