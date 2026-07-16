import Foundation

public protocol EntityProgressMutating: Sendable {
    func updateProgress(
        id: UUID,
        request: EntityProgressUpdateRequest
    ) async throws -> EntityDetail
}
