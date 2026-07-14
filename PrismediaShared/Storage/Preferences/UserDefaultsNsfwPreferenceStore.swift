import Foundation

public final class UserDefaultsNsfwPreferenceStore: NsfwPreferenceStoring {
    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "prismedia.allowsNsfwContent"
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func load(for userID: UUID) -> Bool {
        defaults.bool(forKey: key(for: userID))
    }

    public func save(_ allowsNsfwContent: Bool, for userID: UUID) {
        defaults.set(allowsNsfwContent, forKey: key(for: userID))
    }

    private func key(for userID: UUID) -> String {
        "\(keyPrefix).\(userID.uuidString.lowercased())"
    }
}
