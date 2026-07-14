import Foundation

public protocol CollectionManaging: Sendable {
    func createCollection(_ request: CollectionWriteRequest) async throws -> CollectionDefinition
    func updateCollection(id: UUID, request: CollectionWriteRequest) async throws -> CollectionDefinition
    func deleteCollection(id: UUID) async throws -> UUID
}
