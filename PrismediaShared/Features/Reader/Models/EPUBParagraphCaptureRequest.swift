import Foundation

/// Identifies one paragraph measurement for a position the EPUB navigator reported.
struct EPUBParagraphCaptureRequest: Equatable, Sendable {
    /// Orders measurements so only the one for the latest reported position can be applied.
    let generation: Int
    /// The navigator's serialized locator that a measured paragraph anchor enriches.
    let location: String
    /// The reading-order resource that contains `location`.
    let resourceKey: String
}
