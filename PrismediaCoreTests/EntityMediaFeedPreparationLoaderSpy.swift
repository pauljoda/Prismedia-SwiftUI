import Foundation

@testable import PrismediaCore

actor EntityMediaFeedPreparationLoaderSpy: EntityDetailLoading, EntityImageSourceLoading {
    private let details: [UUID: EntityDetail]
    private let sources: [UUID: Data]
    private var detailRequestIDs: [UUID] = []
    private var sourceRequestIDs: [UUID] = []

    init(details: [UUID: EntityDetail], sources: [UUID: Data] = [:]) {
        self.details = details
        self.sources = sources
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        detailRequestIDs.append(id)
        guard let detail = details[id] else { throw URLError(.resourceUnavailable) }
        return detail
    }

    func loadEntitySourceData(id: UUID) async throws -> Data {
        sourceRequestIDs.append(id)
        guard let source = sources[id] else { throw URLError(.resourceUnavailable) }
        return source
    }

    func requestedDetailIDs() -> [UUID] {
        detailRequestIDs
    }

    func requestedSourceIDs() -> [UUID] {
        sourceRequestIDs
    }
}
