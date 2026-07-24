struct VideoCompatibilityPlaybackOpeningState {
    private var pausesAfterOpening = false

    mutating func prepare(hasRequestedPlayback: Bool) {
        pausesAfterOpening = !hasRequestedPlayback
    }

    mutating func requestPlayback() {
        pausesAfterOpening = false
    }

    mutating func shouldPauseAfterOpening() -> Bool {
        defer { pausesAfterOpening = false }
        return pausesAfterOpening
    }
}
