enum VideoPlaybackReadiness {
    static func isInteractive(playerReady: Bool, optionsReady: Bool) -> Bool {
        playerReady && optionsReady
    }
}
