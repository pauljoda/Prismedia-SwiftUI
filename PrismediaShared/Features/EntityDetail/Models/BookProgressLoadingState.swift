import Foundation

struct BookProgressLoadingState: Equatable, Sendable {
    private(set) var isLoading = true
    private var generation = 0

    mutating func begin() -> Int {
        generation += 1
        isLoading = true
        return generation
    }

    mutating func finish(_ request: Int) {
        guard request == generation else { return }
        isLoading = false
    }
}
