import Foundation

public struct ReaderPreferencesStore: @unchecked Sendable {
    public static let epubDefaultsKey = "prismedia.reader.epub.preferences.v1"

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

    public func loadEPUB() -> EPUBReaderPreferences {
        guard
            let data = defaults?.data(forKey: Self.epubDefaultsKey),
            let preferences = try? JSONDecoder().decode(EPUBReaderPreferences.self, from: data)
        else { return EPUBReaderPreferences() }
        return preferences
    }

    public func save(_ preferences: EPUBReaderPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults?.set(data, forKey: Self.epubDefaultsKey)
    }
}
