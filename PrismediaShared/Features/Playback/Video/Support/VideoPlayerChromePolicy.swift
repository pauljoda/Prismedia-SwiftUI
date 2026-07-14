enum VideoPlayerChromePolicy {
    static func shouldAutoHide(isPlaying: Bool, optionsPresented: Bool) -> Bool { isPlaying && !optionsPresented }
}
