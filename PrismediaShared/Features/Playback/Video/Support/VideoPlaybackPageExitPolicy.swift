enum VideoPlaybackPageExitPolicy {
    static func shouldReleasePlayback(pictureInPictureIsActiveOrStarting: Bool) -> Bool {
        !pictureInPictureIsActiveOrStarting
    }
}
