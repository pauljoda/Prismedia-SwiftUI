enum VideoRenderReadinessPolicy {
    static let deadline: Duration = .seconds(5)

    static func shouldRecover(
        isSurfaceAttached: Bool,
        isReadyForDisplay: Bool,
        isPlaying: Bool,
        isWaiting: Bool,
        playbackAdvance: Double
    ) -> Bool {
        isSurfaceAttached
            && !isReadyForDisplay
            && isPlaying
            && !isWaiting
            && playbackAdvance >= 1
    }
}
