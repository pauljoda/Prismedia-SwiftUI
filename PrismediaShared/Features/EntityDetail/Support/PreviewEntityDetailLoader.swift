import Foundation

struct PreviewEntityDetailLoader: EntityDetailLoading {
    let detail: EntityDetail

    func loadEntity(id: UUID) async throws -> EntityDetail {
        detail
    }
}
