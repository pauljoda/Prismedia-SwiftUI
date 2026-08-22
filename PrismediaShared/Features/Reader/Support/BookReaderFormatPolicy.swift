import Foundation

public struct BookReaderFormatPolicy: Sendable {
    public static func route(
        for kind: EntityKind,
        format: BookFormat?
    ) -> BookReaderFormatRoute {
        return route(for: format)
    }

    public static func route(for format: BookFormat?) -> BookReaderFormatRoute {
        guard let format else { return .unavailable }
        if format == .pdf { return .pdf }
        if format == .epub { return .epub }
        return .unsupported(format)
    }
}
