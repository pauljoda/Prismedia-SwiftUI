import Foundation

enum CollectionMembersPhase: Equatable, Sendable {
    case idle
    case loading
    case content([EntityThumbnail])
    case failure(String)
}
