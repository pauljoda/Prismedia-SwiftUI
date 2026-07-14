@MainActor
public protocol MusicPlaybackStatePersisting: AnyObject {
    func load() -> MusicPlaybackRestoration?
    func save(_ restoration: MusicPlaybackRestoration)
    func clear()
    func loadPreferences() -> MusicPlaybackPreferences?
    func savePreferences(_ preferences: MusicPlaybackPreferences)
}

extension MusicPlaybackStatePersisting {
    public func loadPreferences() -> MusicPlaybackPreferences? {
        load().map {
            MusicPlaybackPreferences(
                repeatMode: $0.repeatMode,
                isShuffled: $0.isShuffled
            )
        }
    }

    public func savePreferences(_ preferences: MusicPlaybackPreferences) {}
}
