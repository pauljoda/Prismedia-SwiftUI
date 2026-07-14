import Foundation

public enum SearchHubState: Equatable, Sendable {
    case idle
    case loading
    case content
    case empty
    case failed(String)
}
