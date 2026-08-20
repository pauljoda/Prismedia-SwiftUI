enum VLCNetworkCachingSettings {
    /// The compatibility engine shipped and was validated with a hardcoded 20-second
    /// network cache. When the value became configurable it silently defaulted to 3
    /// seconds, which starves VLC's buffering completion signal — Dolby Vision
    /// Profile 5 playback then holds its loading overlay forever while the media
    /// plays underneath. The validated value is the default.
    static let defaultSeconds = 20
    static let secondsRange = 0...60

    /// Dolby Vision Profile 5 playback (VideoToolbox decode reshaped through
    /// libplacebo) was only ever validated with a 20-second cache; smaller values
    /// re-create the stuck loading overlay. A user preference below this floor is
    /// honored for every other stream but clamped for Profile 5.
    static let dolbyVisionProfile5MinimumSeconds = 20

    static func normalizedSeconds(_ seconds: Int) -> Int {
        min(max(seconds, secondsRange.lowerBound), secondsRange.upperBound)
    }

    static func effectiveSeconds(_ seconds: Int, dolbyVisionProfile: Int?) -> Int {
        let normalized = normalizedSeconds(seconds)
        guard dolbyVisionProfile == 5 else { return normalized }
        return max(normalized, dolbyVisionProfile5MinimumSeconds)
    }

    static func milliseconds(for seconds: Int) -> Int {
        normalizedSeconds(seconds) * 1_000
    }

    static func milliseconds(for seconds: Int, dolbyVisionProfile: Int?) -> Int {
        effectiveSeconds(seconds, dolbyVisionProfile: dolbyVisionProfile) * 1_000
    }
}
