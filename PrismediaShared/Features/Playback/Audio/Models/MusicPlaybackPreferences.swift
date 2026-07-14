import Foundation

public struct MusicPlaybackPreferences: Codable, Equatable, Sendable {
    public var repeatMode: MusicRepeatMode
    public var isShuffled: Bool

    public init(
        repeatMode: MusicRepeatMode = .off,
        isShuffled: Bool = false
    ) {
        self.repeatMode = repeatMode
        self.isShuffled = isShuffled
    }

    init(queue: MusicQueue) {
        repeatMode = queue.repeatMode
        isShuffled = queue.isShuffled
    }
}
