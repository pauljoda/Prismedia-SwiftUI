import Foundation

public protocol EntityMetadataMutating: Sendable {
    func updateMetadata(
        id: UUID,
        kind: EntityKind,
        request: EntityDetailMetadataUpdateRequest
    ) async throws -> EntityDetail
}
