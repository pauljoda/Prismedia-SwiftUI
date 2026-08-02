import Foundation

public enum ConsumptionStatisticsState: Equatable, Sendable {
    case idle
    case loading
    case content
    case empty
    case failed(String)
}
