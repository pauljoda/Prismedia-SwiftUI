import Foundation

@MainActor
protocol VideoPlaybackEnginePreferenceStoring {
    func load() -> VideoPlaybackEngine
    func save(_ engine: VideoPlaybackEngine)
}
