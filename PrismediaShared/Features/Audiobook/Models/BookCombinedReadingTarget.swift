import Foundation

enum BookCombinedReadingTarget: Equatable, Sendable {
    case savedLocation
    case chapter(location: String, progression: Double)
}
