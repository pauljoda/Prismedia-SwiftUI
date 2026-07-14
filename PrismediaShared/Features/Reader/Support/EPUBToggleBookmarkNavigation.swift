import Foundation

public struct EPUBToggleBookmarkNavigation: Hashable, Sendable {
    private var returnLocator: String?

    public init() {}

    public var isReturnAvailable: Bool {
        returnLocator != nil
    }

    public var shouldRecordProgress: Bool {
        returnLocator == nil
    }

    public mutating func destination(
        toggleBookmarkLocator: String,
        currentLocator: String
    ) -> String {
        guard let returnLocator else {
            self.returnLocator = currentLocator
            return toggleBookmarkLocator
        }

        self.returnLocator = nil
        return returnLocator
    }

    public mutating func reset() {
        returnLocator = nil
    }
}
