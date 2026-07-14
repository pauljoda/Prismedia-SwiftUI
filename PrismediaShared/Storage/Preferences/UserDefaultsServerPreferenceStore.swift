import Foundation

public final class UserDefaultsServerPreferenceStore: ServerPreferenceStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "prismedia.lastServerURL"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> URL? {
        defaults.string(forKey: key).flatMap(URL.init(string:))
    }

    public func save(_ serverURL: URL) {
        defaults.set(serverURL.absoluteString, forKey: key)
    }
}
