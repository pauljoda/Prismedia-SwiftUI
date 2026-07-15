import Foundation

@testable import PrismediaCore

actor AudiobookQueueDetailLoaderSpy: EntityDetailLoading {
    private let detailsByID: [UUID: EntityDetail]
    private let requestDelay: Duration
    private var requestedIDs: [UUID] = []
    private var activeRequests = 0
    private var maximumConcurrentRequests = 0

    init(
        detailsByID: [UUID: EntityDetail],
        requestDelay: Duration = .zero
    ) {
        self.detailsByID = detailsByID
        self.requestDelay = requestDelay
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        requestedIDs.append(id)
        activeRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequests)
        defer { activeRequests -= 1 }

        if requestDelay > .zero {
            try await Task.sleep(for: requestDelay)
        }
        guard let detail = detailsByID[id] else { throw CancellationError() }
        return detail
    }

    func metrics() -> (requestedIDs: [UUID], maximumConcurrentRequests: Int) {
        (requestedIDs, maximumConcurrentRequests)
    }
}
