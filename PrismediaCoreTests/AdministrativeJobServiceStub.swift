import Foundation

@testable import PrismediaCore

actor AdministrativeJobServiceStub: AdministrativeJobServicing {
    var response = AdministrativeJobListResponse(items: [], counts: [])
    var readError: (any Error)?
    var mutationError: (any Error)?
    var heldRead: CheckedContinuation<AdministrativeJobListResponse, any Error>?
    var shouldHoldRead = false
    private(set) var mutationCount = 0

    func configure(
        response: AdministrativeJobListResponse? = nil, readError: (any Error)? = nil,
        mutationError: (any Error)? = nil
    ) {
        if let response { self.response = response }
        self.readError = readError
        self.mutationError = mutationError
    }

    func holdNextRead() { shouldHoldRead = true }
    func isReadHeld() -> Bool { heldRead != nil }
    func finishHeldRead(_ value: AdministrativeJobListResponse) {
        heldRead?.resume(returning: value)
        heldRead = nil
    }

    func jobs() async throws -> AdministrativeJobListResponse {
        if shouldHoldRead {
            shouldHoldRead = false
            return try await withCheckedThrowingContinuation { heldRead = $0 }
        }
        if let readError { throw readError }
        return response
    }

    func createJob(type: String) async throws -> AdministrativeJobRun {
        try mutate()
        return .init(
            id: UUID(), type: type, status: "queued", progress: 0, message: nil,
            targetKind: nil, targetID: nil, targetLabel: nil, createdAt: .now,
            startedAt: nil, finishedAt: nil)
    }

    func cancelJob(id: UUID) async throws -> Int { try mutate() }
    func cancelJobs(type: String?) async throws -> Int { try mutate() }
    func clearFailures(type: String?) async throws -> Int { try mutate() }

    @discardableResult
    private func mutate() throws -> Int {
        mutationCount += 1
        if let mutationError { throw mutationError }
        return 1
    }
}
