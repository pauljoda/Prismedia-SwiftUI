import Foundation

public struct SearchHubSearchRequest: Sendable {
    let generation: Int
    let query: String
    let filters: SearchHubFilterState
    let cursor: String?
}
