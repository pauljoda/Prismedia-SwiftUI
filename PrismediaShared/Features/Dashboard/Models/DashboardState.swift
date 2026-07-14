import Foundation

public enum DashboardState: Equatable, Sendable {
    case idle
    case loading
    case content
    case empty
}
