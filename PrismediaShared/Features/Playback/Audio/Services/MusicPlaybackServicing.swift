import Foundation

@MainActor
public protocol MusicPlaybackServicing: Sendable {
    var isPlaybackAvailable: Bool { get }
    func audioStreamURL(for trackID: UUID) -> URL?
    func artworkURL(for path: String?) -> URL?
    func recordAudioTrackPlay(id: UUID) async throws
    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws
}

extension MusicPlaybackServicing {
    public var isPlaybackAvailable: Bool { true }
    public func artworkURL(for path: String?) -> URL? { nil }
}
