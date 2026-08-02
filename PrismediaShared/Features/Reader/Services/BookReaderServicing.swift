import Foundation
import ImageIO
import Observation

typealias PlatformReaderImage = CGImage

public protocol BookReaderServicing: EntityDetailLoading, Sendable {
    func loadPageData(id: UUID) async throws -> Data
    func loadSourceData(id: UUID) async throws -> Data
    /// Records one user access when a reader presentation opens a book.
    func recordReadingAccess(id: UUID, sessionID: String) async throws
    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws
}

extension BookReaderServicing {
    public func loadSourceData(id: UUID) async throws -> Data {
        try await loadPageData(id: id)
    }

    public func recordReadingAccess(id: UUID, sessionID: String) async throws {}
}

extension PrismediaEntityDetailLoader: BookReaderServicing {
    public func loadPageData(id: UUID) async throws -> Data {
        try await client.entitySourceData(id: id)
    }

    public func loadSourceData(id: UUID) async throws -> Data {
        try await client.entitySourceData(id: id)
    }

    public func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        _ = try await client.updateEntityProgress(id: id, request: request)
    }

    public func recordReadingAccess(id: UUID, sessionID: String) async throws {
        try await client.recordEntityConsumptionEvent(
            id: id,
            kind: .accessed,
            positionSeconds: nil,
            durationSeconds: nil,
            sessionID: sessionID
        )
    }
}
