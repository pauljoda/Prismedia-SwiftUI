import Foundation

enum EntityDetailMutationOutcome: Sendable {
    case content(EntityDetail)
    case failure(String)
    case cancelled
    case unavailable
}
