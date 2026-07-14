import Foundation

struct CollectionMembersRequest: Equatable, Sendable {
    let collectionID: UUID
    let generation: Int
}
