import Foundation

public struct EntityGridCardStylePreferenceStore: @unchecked Sendable {
    private static let key = "prismedia.app-settings.entity-grid-card-style.v1"

    private let defaults: UserDefaults?

    public static var standard: Self {
        EntityGridCardStylePreferenceStore(defaults: .standard)
    }

    public static var disabled: Self {
        EntityGridCardStylePreferenceStore(defaults: nil)
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func load() -> EntityGridCardStyle {
        guard
            let rawValue = defaults?.string(forKey: Self.key),
            let style = EntityGridCardStyle(rawValue: rawValue)
        else { return .artworkFade }
        return style
    }

    public func save(_ style: EntityGridCardStyle) {
        defaults?.set(style.rawValue, forKey: Self.key)
    }
}
