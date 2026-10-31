enum VideoPlayerChromePolicy {
    static let tvAutoHideDelay: Duration = .seconds(3)

    /// Whether playback chrome may hide itself. It stays while playback is paused,
    /// while options are open, and while the person is scrubbing the timeline.
    static func shouldAutoHide(
        isPlaying: Bool,
        optionsPresented: Bool,
        isScrubbing: Bool = false
    ) -> Bool {
        isPlaying && !optionsPresented && !isScrubbing
    }
}
