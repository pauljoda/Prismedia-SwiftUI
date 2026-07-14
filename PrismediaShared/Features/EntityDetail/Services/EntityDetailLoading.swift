import Foundation

public protocol EntityDetailLoading: Sendable {
    func loadEntity(id: UUID) async throws -> EntityDetail
    func loadEntity(id: UUID, kind: EntityKind) async throws -> EntityDetail
}

extension EntityDetailLoading {
    public func loadEntity(id: UUID, kind: EntityKind) async throws -> EntityDetail {
        try await loadEntity(id: id)
    }
}
