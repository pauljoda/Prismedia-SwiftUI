import Foundation

public protocol EntityImageVideoAspectRatioLoading: Sendable {
    func loadVideoAspectRatio(path: String) async throws -> Double
}
