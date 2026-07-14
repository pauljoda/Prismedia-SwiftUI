enum VideoPlaybackVisibilityPolicy {
    static func shouldEnterPictureInPicture(isPlaying: Bool, isWaiting: Bool, playerRate: Float) -> Bool {
        isPlaying || isWaiting || playerRate != 0
    }
}
