enum VLCNetworkCachingSettings {
    static let defaultSeconds = 3
    static let secondsRange = 0...60

    static func normalizedSeconds(_ seconds: Int) -> Int {
        min(max(seconds, secondsRange.lowerBound), secondsRange.upperBound)
    }

    static func milliseconds(for seconds: Int) -> Int {
        normalizedSeconds(seconds) * 1_000
    }
}
