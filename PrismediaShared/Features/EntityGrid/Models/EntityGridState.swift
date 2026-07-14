import Foundation

public enum EntityGridState: Equatable, Sendable {
    case idle
    case loading
    case content
    case empty
    case failed(String)
}
