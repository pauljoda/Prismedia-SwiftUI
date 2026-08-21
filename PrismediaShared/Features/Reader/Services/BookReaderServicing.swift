import Foundation
import ImageIO
import Observation

typealias PlatformReaderImage = CGImage

public protocol BookReaderServicing: EntityPageReaderServicing, Sendable {
    func loadPageData(id: UUID) async throws -> Data
    func loadSourceData(id: UUID) async throws -> Data
    /// Records one user access when a reader presentation opens a book.
    func recordReadingAccess(id: UUID, sessionID: String) async throws
    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws
}

extension BookReaderServicing {
    public func loadPageData(page: BookReaderPage) async throws -> Data {
        switch page.source {
        case .entity(let id):
            try await loadPageData(id: id)
        case .manifest(let entityID, let ordinal):
            try await loadEntityReaderPageData(id: entityID, ordinal: ordinal)
        }
    }

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

    public func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
        try await client.entityReaderManifest(id: id)
    }

    public func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
        try await client.entityReaderPageData(id: id, ordinal: ordinal)
    }

    public func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        try await client.reportEntityProgress(id: id, request: request)
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
