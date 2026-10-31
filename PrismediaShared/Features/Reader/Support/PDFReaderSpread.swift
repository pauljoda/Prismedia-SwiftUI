import Foundation

/// Paging through a PDF shown as two-page spreads in landscape: pages pair up as
/// 1–2, 3–4 and so on, a left and a right page like an open book, and a last odd
/// page stands alone. Indexes are zero-based page indexes.
enum PDFReaderSpread {
    /// The first page of the spread that shows `index`.
    static func firstPage(showing index: Int) -> Int {
        max(0, index - index % 2)
    }

    static func nextPage(from index: Int, pageCount: Int) -> Int {
        let first = firstPage(showing: index)
        let next = first + 2
        return next < pageCount ? next : first
    }

    static func previousPage(from index: Int) -> Int {
        max(0, firstPage(showing: index) - 2)
    }

    /// Whether a later spread exists after the one showing `index`.
    static func hasNextPage(from index: Int, pageCount: Int) -> Bool {
        nextPage(from: index, pageCount: pageCount) != firstPage(showing: index)
    }
}
