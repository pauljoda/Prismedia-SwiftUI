import Foundation

enum EntityDetailLoadOutcome: Sendable {
    case content(EntityDetail)
    case failure(String)
    case cancelled
}
