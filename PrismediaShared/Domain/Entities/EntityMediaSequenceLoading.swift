@MainActor
public protocol EntityMediaSequenceLoading: Sendable {
    func loadNextPage(
        _ request: EntityMediaSequencePageRequest
    ) async throws -> EntityMediaSequencePage
}
