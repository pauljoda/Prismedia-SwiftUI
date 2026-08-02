import Foundation

@MainActor
public protocol MusicPlaybackServicing: Sendable {
    var isPlaybackAvailable: Bool { get }
    func audioStreamURL(for trackID: UUID) -> URL?
    func artworkURL(for path: String?) -> URL?
    func recordAudioTrackPlay(id: UUID) async throws
    func recordEntityPlaybackEvent(
        id: UUID,
        kind: ConsumptionEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionID: String?
    ) async throws
    func updateEntityPlayback(
        id: UUID,
        resumeSeconds: Double?,
        activitySeconds: Double?,
        completed: Bool?
    ) async throws
    func reportEntityProgress(id: UUID, request: EntityProgressUpdateRequest) async throws
}

extension MusicPlaybackServicing {
    public var isPlaybackAvailable: Bool { true }
    public func artworkURL(for path: String?) -> URL? { nil }
    public func recordEntityPlaybackEvent(
        id: UUID,
        kind: ConsumptionEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionID: String? = nil
    ) async throws {}
    public func updateEntityPlayback(
        id: UUID,
        resumeSeconds: Double?,
        activitySeconds: Double?,
        completed: Bool?
    ) async throws {}
}
