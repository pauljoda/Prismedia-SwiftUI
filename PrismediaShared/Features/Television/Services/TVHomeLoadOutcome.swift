import Foundation

enum TVHomeLoadOutcome: Sendable {
    case success(id: String, items: [EntityThumbnail])
    case failure(id: String)
}
