import Foundation

public struct SearchHubPage: Equatable, Sendable {
    let items: [EntityThumbnail]
    let totalCount: Int
    let nextCursor: String?
}
