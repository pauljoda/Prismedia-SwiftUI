import Foundation

public enum PlaybackStatisticsState: Equatable, Sendable {
    case idle
    case loading
    case content
    case empty
    case failed(String)
}
