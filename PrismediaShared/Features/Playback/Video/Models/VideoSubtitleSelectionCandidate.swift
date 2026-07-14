import Foundation

struct VideoSubtitleSelectionCandidate: Equatable, Sendable {
    let id: String
    let language: String?
    let label: String?
}
