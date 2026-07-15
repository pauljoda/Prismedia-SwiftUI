import Foundation

enum EntityDetailEditOutcome: Hashable, Sendable {
    case saved
    case failed(message: String, savedPartialChanges: Bool)
}
