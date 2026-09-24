import Foundation

/// The paragraph the reading script measured at the document's current scroll offset.
struct EPUBParagraphViewport: Decodable, Equatable, Sendable {
    // MARK: - Static Variables

    /// Scroll offsets within this distance, in CSS pixels, describe the same reading position.
    private static let scrollOffsetTolerance = 1.0

    // MARK: - Variables

    /// The paragraph at the reading position, or `nil` when no readable paragraph starts there.
    let anchor: EPUBParagraphAnchor?
    /// The document's horizontal scroll offset; paged chapters advance it one page at a time.
    let scrollX: Double
    /// The document's vertical scroll offset; scrolled chapters advance it continuously.
    let scrollY: Double

    // MARK: - Actions - Comparison

    /// Whether this measurement was taken at the same scroll offset as `other`.
    func isAtScrollOffset(of other: Self) -> Bool {
        abs(scrollX - other.scrollX) <= Self.scrollOffsetTolerance
            && abs(scrollY - other.scrollY) <= Self.scrollOffsetTolerance
    }
}

extension EPUBParagraphViewport {
    // MARK: - Initializers

    /// Decodes the JSON text the reading script returns. Script failures and `null` produce `nil`.
    init?(scriptResult: Any?) {
        guard let json = scriptResult as? String,
            let data = json.data(using: .utf8),
            let viewport = try? JSONDecoder().decode(Self.self, from: data)
        else { return nil }
        self = viewport
    }
}
