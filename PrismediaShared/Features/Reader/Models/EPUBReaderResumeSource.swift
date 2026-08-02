import Foundation

enum EPUBReaderResumeSource: Equatable, Sendable {
    case explicitLocator(String)
    case explicit(BookReaderLocationTarget)
    case device(String)

    var fallbackTarget: BookReaderLocationTarget? {
        switch self {
        case .explicitLocator(let location):
            EPUBReaderResumeSourceResolver().locationTarget(
                location: location,
                progression: nil
            )
        case .explicit(let target):
            target
        case .device(let location):
            EPUBReaderResumeSourceResolver().locationTarget(
                location: location,
                progression: nil
            )
        }
    }

    var serializedLocation: String? {
        switch self {
        case .explicitLocator(let location), .device(let location):
            location
        case .explicit:
            nil
        }
    }
}
