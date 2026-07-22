import Foundation

enum EntityAcquisitionMutationOutcome: Equatable, Sendable {
    case completed(entityPruned: Bool)
    case missingChildrenSearchCompleted(EntityMissingChildrenSearchResponse)
    case failure(String)
    case cancelled
}
