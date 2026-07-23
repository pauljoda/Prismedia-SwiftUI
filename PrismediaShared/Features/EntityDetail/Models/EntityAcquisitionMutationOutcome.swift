import Foundation

enum EntityAcquisitionMutationOutcome: Equatable, Sendable {
    case completed(entityPruned: Bool)
    case filesDeleted(EntityDeleteResponse)
    case missingChildrenSearchCompleted(EntityMissingChildrenSearchResponse)
    case failure(String)
    case cancelled
}
