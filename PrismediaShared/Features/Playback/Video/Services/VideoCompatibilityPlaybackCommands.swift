@MainActor
struct VideoCompatibilityPlaybackCommands {
    let play: (Float) -> Void
    let pause: () -> Void
    let seek: (Double) -> Void
    let stop: () -> Void
    let setRate: (Float) -> Void
    let selectAudioStream: (Int) -> Void
}
