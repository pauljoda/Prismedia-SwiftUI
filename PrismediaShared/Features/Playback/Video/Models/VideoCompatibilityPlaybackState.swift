struct VideoCompatibilityPlaybackState: Equatable, Sendable {
    var currentTime: Double
    let duration: Double
    let isPlaying: Bool
    let isWaiting: Bool
}
