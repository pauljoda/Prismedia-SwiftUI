import Foundation

public struct EPUBLocatorStore: @unchecked Sendable {
    private static let keyPrefix = "prismedia.reader.epub.locator.v1."

    private let defaults: UserDefaults?

    public static var standard: Self {
        Self(defaults: .standard)
    }

    public static var disabled: Self {
        Self(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func load(bookID: UUID) -> String? {
        defaults?.string(forKey: key(bookID))
    }

    public func save(_ locator: String, bookID: UUID) {
        defaults?.set(locator, forKey: key(bookID))
    }

    private func key(_ bookID: UUID) -> String {
        Self.keyPrefix + bookID.uuidString.lowercased()
    }
}
