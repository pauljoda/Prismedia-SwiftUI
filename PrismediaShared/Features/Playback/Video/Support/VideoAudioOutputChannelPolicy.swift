enum VideoAudioOutputChannelPolicy {
    private static let maximumSupportedChannelCount = 8

    static func preferredChannelCount(maximumAvailable: Int) -> Int? {
        guard maximumAvailable > 0 else { return nil }
        return min(maximumAvailable, maximumSupportedChannelCount)
    }
}
