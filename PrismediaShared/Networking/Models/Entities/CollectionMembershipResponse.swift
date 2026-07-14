import Foundation

struct CollectionMembershipResponse: Decodable, Sendable {
    let items: [CollectionMembership]
}
