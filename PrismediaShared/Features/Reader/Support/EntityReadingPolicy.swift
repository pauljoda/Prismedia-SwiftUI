import Foundation

/// Resolves reader behavior from generic page-sequence capability or supported prose formats.
enum EntityReadingPolicy {
    static func supportsReading(_ detail: EntityDetail) -> Bool {
        if let pages = detail.capability(EntityPageSequenceCapability.self), pages.pageCount > 0 {
            return true
        }

        switch detail.kind {
        case .book:
            guard detail.hasSourceMedia else { return false }
            switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
            case .pdf, .epub:
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
        case .unavailable, .unsupported:
            return false
        }
    }
}
