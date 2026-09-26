import Foundation

/// Where an EPUB reader session stands between restoring an exact location and following the reader.
enum EPUBExactLocationPhase: Equatable, Sendable {
    /// Reported positions come from the reader's own movement and are accepted.
    case following
    /// A saved paragraph is being placed in `resourceKey`; reported positions are programmatic.
    case restoring(resourceKey: String, anchor: EPUBParagraphAnchor)
    /// The restored paragraph settled at `landing`, or at the next measured offset when `landing`
    /// is `nil`. Positions there stay programmatic until the reader moves.
    case holding(resourceKey: String, landing: EPUBParagraphViewport?)
    /// The reader closed; nothing further is accepted.
    case closed
}
