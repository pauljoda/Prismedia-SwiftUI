import Foundation

public protocol CollectionMembershipLoading: Sendable {
    func loadCollectionMemberships(collectionID: UUID) async throws -> [CollectionMembership]
}
