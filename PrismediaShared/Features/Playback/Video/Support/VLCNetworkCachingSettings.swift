enum VLCNetworkCachingSettings {
    /// Keep enough data queued to absorb ordinary network jitter without turning
    /// every resume or seek into a long pre-roll. The setting is presented in
    /// seconds and translated to libVLC's millisecond option at the boundary.
    static let defaultSeconds = 3
    static let secondsRange = 0...60

    static func normalizedSeconds(_ seconds: Int) -> Int {
        min(max(seconds, secondsRange.lowerBound), secondsRange.upperBound)
    }

    static func effectiveSeconds(_ seconds: Int, dolbyVisionProfile _: Int?) -> Int {
        normalizedSeconds(seconds)
    }

    static func milliseconds(for seconds: Int) -> Int {
        normalizedSeconds(seconds) * 1_000
    }

    static func milliseconds(for seconds: Int, dolbyVisionProfile: Int?) -> Int {
        effectiveSeconds(seconds, dolbyVisionProfile: dolbyVisionProfile) * 1_000
    }
}
