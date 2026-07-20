enum VideoPlayerChromePolicy {
    static let tvAutoHideDelay: Duration = .seconds(3)

    static func shouldAutoHide(
        isPlaying: Bool,
        optionsPresented: Bool,
        isSeeking: Bool = false
    ) -> Bool {
        isPlaying && !optionsPresented && !isSeeking
    }
}
