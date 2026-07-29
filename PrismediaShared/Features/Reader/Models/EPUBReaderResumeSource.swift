import Foundation

enum EPUBReaderResumeSource: Equatable, Sendable {
    case explicit(BookReaderLocationTarget)
    case device(String)

    var fallbackTarget: BookReaderLocationTarget? {
        switch self {
        case .explicit(let target):
            target
        case .device(let location):
            EPUBReaderResumeSourceResolver().locationTarget(
                location: location,
                progression: nil
            )
        }
    }
}
