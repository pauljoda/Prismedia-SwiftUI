import Foundation

@MainActor
public protocol MusicPlaybackServicing: Sendable {
    var isPlaybackAvailable: Bool { get }
    func audioStreamURL(for trackID: UUID) -> URL?
    func artworkURL(for path: String?) -> URL?
    func recordEntityConsumptionEvent(
        id: UUID,
        kind: ConsumptionEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionID: String?
    ) async throws
    func updateEntityConsumption(
        id: UUID,
        positionSeconds: Double?,
        activitySeconds: Double?,
        completed: Bool?
    ) async throws
    func reportEntityProgress(id: UUID, request: EntityProgressUpdateRequest) async throws
}

extension MusicPlaybackServicing {
    public var isPlaybackAvailable: Bool { true }
    public func artworkURL(for path: String?) -> URL? { nil }
    public func recordEntityConsumptionEvent(
        id: UUID,
        kind: ConsumptionEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionID: String? = nil
    ) async throws {}
    public func updateEntityConsumption(
        id: UUID,
        positionSeconds: Double?,
        activitySeconds: Double?,
        completed: Bool?
    ) async throws {}
}
