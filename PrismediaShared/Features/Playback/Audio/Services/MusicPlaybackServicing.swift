import Foundation

@MainActor
public protocol MusicPlaybackServicing: Sendable {
    func audioStreamURL(for trackID: UUID) -> URL?
    func recordAudioTrackPlay(id: UUID) async throws
    func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws
}
