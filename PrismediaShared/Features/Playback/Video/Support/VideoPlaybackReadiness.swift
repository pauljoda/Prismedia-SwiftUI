enum VideoPlaybackReadiness {
    static func isInteractive(playerReady: Bool, optionsReady: Bool, filmstripReady: Bool) -> Bool {
        playerReady && optionsReady && filmstripReady
    }
}
