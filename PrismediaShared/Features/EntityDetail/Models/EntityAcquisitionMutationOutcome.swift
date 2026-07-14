import Foundation

enum EntityAcquisitionMutationOutcome: Equatable, Sendable {
    case completed(entityPruned: Bool)
    case failure(String)
    case cancelled
}
