import Foundation

@MainActor
struct UserDefaultsVLCNetworkCachingPreferenceStore: VLCNetworkCachingPreferenceStoring {
    static let key = "video.playback.vlc-network-caching-seconds"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSeconds() -> Int {
        guard defaults.object(forKey: Self.key) != nil else {
            return VLCNetworkCachingSettings.defaultSeconds
        }
        let seconds = defaults.integer(forKey: Self.key)
        guard VLCNetworkCachingSettings.secondsRange.contains(seconds) else {
            return VLCNetworkCachingSettings.defaultSeconds
        }
        return seconds
    }

    func saveSeconds(_ seconds: Int) {
        defaults.set(
            VLCNetworkCachingSettings.normalizedSeconds(seconds),
            forKey: Self.key
        )
    }
}
