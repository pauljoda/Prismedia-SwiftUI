import Foundation

struct CollectionMembershipOption: Decodable {
    let id: UUID
    let title: String
}

struct CollectionMembershipOptionsResponse: Decodable {
    let items: [CollectionMembershipOption]
}
