import Foundation

enum DashboardHeroPagingPolicy {
    static func nextIndex(from currentIndex: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return min(max(currentIndex, 0) + 1, itemCount - 1)
    }

    static func previousIndex(from currentIndex: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return max(min(currentIndex, itemCount - 1) - 1, 0)
    }
}
