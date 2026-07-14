import Foundation

enum CollectionMembersLoadOutcome: Equatable, Sendable {
    case content([EntityThumbnail])
    case failure(String)
    case cancelled
    case unavailable
}
