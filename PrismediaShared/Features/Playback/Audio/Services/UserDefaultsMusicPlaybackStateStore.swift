import Foundation

@MainActor
public final class UserDefaultsMusicPlaybackStateStore: MusicPlaybackStatePersisting {
    private static let stateKey = "prismedia.music.playback-restoration.v1"
    private static let preferencesKey = "prismedia.music.playback-preferences.v1"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> MusicPlaybackRestoration? {
        guard let data = defaults.data(forKey: Self.stateKey) else { return nil }
        return try? decoder.decode(MusicPlaybackRestoration.self, from: data)
    }

    public func save(_ restoration: MusicPlaybackRestoration) {
        guard let data = try? encoder.encode(restoration) else { return }
        defaults.set(data, forKey: Self.stateKey)
    }

    public func clear() {
        defaults.removeObject(forKey: Self.stateKey)
    }

    public func loadPreferences() -> MusicPlaybackPreferences? {
        if let data = defaults.data(forKey: Self.preferencesKey),
            let preferences = try? decoder.decode(MusicPlaybackPreferences.self, from: data)
        {
            return preferences
        }

        return load().map {
            MusicPlaybackPreferences(
                repeatMode: $0.repeatMode,
                isShuffled: $0.isShuffled
            )
        }
    }

    public func savePreferences(_ preferences: MusicPlaybackPreferences) {
        guard let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: Self.preferencesKey)
    }
}
