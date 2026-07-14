import Foundation

public struct SearchHubSearchRequest: Sendable {
    let generation: Int
    let query: String
    let cursor: String?
}
