import Foundation

enum BookCombinedPreferredPosition: Sendable {
    case reading(index: Int, fraction: Double)
    case listening(index: Int, fraction: Double)
}
