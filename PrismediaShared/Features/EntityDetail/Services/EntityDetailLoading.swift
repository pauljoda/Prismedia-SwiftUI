import Foundation

public protocol EntityDetailLoading: Sendable {
    func loadEntity(id: UUID) async throws -> EntityDetail
}
