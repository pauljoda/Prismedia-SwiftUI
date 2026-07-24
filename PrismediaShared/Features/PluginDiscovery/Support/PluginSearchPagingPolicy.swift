import Foundation

enum PluginSearchPagingPolicy {
    static let pageSize = 25
    static let maximumLimit = 100

    static func nextLimit(
        after currentLimit: Int
    ) -> Int? {
        guard currentLimit < maximumLimit else { return nil }
        return min(maximumLimit, max(pageSize, currentLimit) + pageSize)
    }
}
