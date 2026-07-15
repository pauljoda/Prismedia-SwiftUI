import Foundation

struct EntityDetailReferenceSearchService: Sendable {
    private let loader: any EntityGridLoading

    init(loader: any EntityGridLoading) {
        self.loader = loader
    }

    func search(kind: EntityKind, query: String) async throws -> [EntityDetailReferenceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = try await loader.load(
            query: EntityListQuery(kind: kind, sort: "title", sortDescending: false),
            limit: 20,
            search: trimmed.isEmpty ? nil : trimmed,
            cursor: nil
        )
        return response.items.map(EntityDetailReferenceDraft.init(thumbnail:))
    }
}
