import Foundation

public protocol TrickplayFrameLoading: Sendable {
    func loadFrames(playlistPath: String) async -> [TrickplayPlaylist.Frame]
}
