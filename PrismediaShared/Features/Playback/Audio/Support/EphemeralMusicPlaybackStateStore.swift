import Foundation

@MainActor
final class EphemeralMusicPlaybackStateStore: MusicPlaybackStatePersisting {
    private var restoration: MusicPlaybackRestoration?
    private var preferences: MusicPlaybackPreferences?

    func load() -> MusicPlaybackRestoration? { restoration }
    func save(_ restoration: MusicPlaybackRestoration) { self.restoration = restoration }
    func saveProgress(_ checkpoint: MusicPlaybackProgressCheckpoint) {
        restoration = restoration?.applying(checkpoint)
    }
    func clear() { restoration = nil }
    func loadPreferences() -> MusicPlaybackPreferences? { preferences }
    func savePreferences(_ preferences: MusicPlaybackPreferences) { self.preferences = preferences }
}
