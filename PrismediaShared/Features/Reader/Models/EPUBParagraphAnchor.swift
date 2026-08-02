import Foundation

/// Identifies the content block nearest the reader's focus line independently of text layout.
struct EPUBParagraphAnchor: Codable, Equatable, Sendable {
    let index: Int
    let text: String?
}
