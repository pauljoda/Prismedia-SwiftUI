enum VideoPlayerChromePolicy {
    static let tvAutoHideDelay: Duration = .seconds(3)

    static func shouldAutoHide(
        isPlaying: Bool,
        optionsPresented: Bool
    ) -> Bool {
        isPlaying && !optionsPresented
    }
}
