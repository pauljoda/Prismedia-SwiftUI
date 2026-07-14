import Foundation

public struct EPUBBookmarkStore: EPUBBookmarkStoring, @unchecked Sendable {
    private static let keyPrefix = "prismedia.reader.epub.bookmarks.v1."

    private let defaults: UserDefaults?
    private let scope: EPUBBookmarkScope?

    public static func standard(scope: EPUBBookmarkScope) -> Self {
        Self(defaults: .standard, scope: scope)
    }

    public static var disabled: Self {
        Self(defaults: nil, scope: nil)
    }

    public init(defaults: UserDefaults, scope: EPUBBookmarkScope) {
        self.defaults = defaults
        self.scope = scope
    }

    private init(defaults: UserDefaults?, scope: EPUBBookmarkScope?) {
        self.defaults = defaults
        self.scope = scope
    }

    public func load(bookID: UUID) -> EPUBBookmarksState {
        guard
            let data = defaults?.data(forKey: key(bookID)),
            let state = try? JSONDecoder().decode(EPUBBookmarksState.self, from: data)
        else { return EPUBBookmarksState() }

        return state
    }

    public func save(_ state: EPUBBookmarksState, bookID: UUID) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: key(bookID))
    }

    private func key(_ bookID: UUID) -> String {
        let scope = scope?.storageKeyFragment ?? "disabled"
        return Self.keyPrefix + scope + "." + bookID.uuidString.lowercased()
    }
}
