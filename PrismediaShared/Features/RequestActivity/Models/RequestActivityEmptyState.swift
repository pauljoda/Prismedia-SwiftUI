import Foundation

public enum RequestActivityEmptyState: Hashable, Sendable {
    case empty
    case filtered

    public static func resolve(sourceCount: Int, visibleCount: Int) -> RequestActivityEmptyState? {
        guard visibleCount == 0 else { return nil }
        return sourceCount == 0 ? .empty : .filtered
    }
}
