import Foundation

public struct EntityThumbnailTextPreferenceStore: @unchecked Sendable {
    private static let key = "prismedia.app-settings.entity-thumbnail-shows-text.v2"
    private static let legacyKey = "prismedia.app-settings.entity-grid-card-style.v1"

    private let defaults: UserDefaults?

    public static var standard: Self {
        EntityThumbnailTextPreferenceStore(defaults: .standard)
    }

    public static var disabled: Self {
        EntityThumbnailTextPreferenceStore(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func load() -> Bool {
        guard let defaults else { return true }
        if defaults.object(forKey: Self.key) != nil {
            return defaults.bool(forKey: Self.key)
        }
        guard let legacyValue = defaults.string(forKey: Self.legacyKey) else { return true }
        return legacyValue != "none"
    }

    public func save(_ showsText: Bool) {
        defaults?.set(showsText, forKey: Self.key)
    }
}
