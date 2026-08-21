import Foundation

/// Resolves reader behavior from Entity capabilities, with legacy prose-book
/// formats retained only for contracts that predate generic page manifests.
enum EntityReadingPolicy {
    static func supportsReading(_ detail: EntityDetail) -> Bool {
        if detail.capability(EntityPageSequenceCapability.self) != nil {
            return true
        }

        switch detail.kind {
        case .bookVolume, .bookChapter:
            return true
        case .book:
            switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
            case .comic, .pdf, .epub:
                return true
            case .unavailable, .unsupported:
                return false
            }
        default:
            return false
        }
    }

    static func isSingleFileDocument(_ detail: EntityDetail) -> Bool {
        guard detail.kind == .book else { return false }
        switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
        case .pdf, .epub:
            return true
        case .unavailable, .comic, .unsupported:
            return false
        }
    }
}
