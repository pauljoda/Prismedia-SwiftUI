import Foundation
import ImageIO
import Observation

typealias PlatformReaderImage = CGImage

public protocol BookReaderServicing: EntityDetailLoading, Sendable {
    func loadPageData(id: UUID) async throws -> Data
    func loadSourceData(id: UUID) async throws -> Data
    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws
}

extension BookReaderServicing {
    public func loadSourceData(id: UUID) async throws -> Data {
        try await loadPageData(id: id)
    }
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
}
