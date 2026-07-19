import Foundation

@MainActor
struct UserDefaultsVideoPlaybackEnginePreferenceStore: VideoPlaybackEnginePreferenceStoring {
    static let key = "video.playback.engine"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> VideoPlaybackEngine {
        guard let value = defaults.string(forKey: Self.key) else { return .automatic }
        return VideoPlaybackEngine(rawValue: value) ?? .automatic
    }

    func save(_ engine: VideoPlaybackEngine) {
        defaults.set(engine.rawValue, forKey: Self.key)
    }
}
