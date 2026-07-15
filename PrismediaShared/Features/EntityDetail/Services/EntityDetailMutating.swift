import Foundation

public protocol EntityDetailMutating: Sendable {
    func updateRating(id: UUID, value: Int?) async throws -> EntityDetail
    func updateFlags(
        id: UUID,
        isFavorite: Bool?,
        isNsfw: Bool?,
        isOrganized: Bool?
    ) async throws -> EntityDetail
}
