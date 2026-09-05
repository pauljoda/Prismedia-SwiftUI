import XCTest

@testable import PrismediaCore

final class AdministrativeJobSessionTests: XCTestCase {
    @MainActor
    func testRefreshFailureRetainsActivityWithoutBecomingAnActionError() async {
        let service = AdministrativeJobServiceStub()
        await service.configure(response: snapshot(3))
        let session = AdministrativeJobSession(service: service)
        await session.refresh()
        await service.configure(readError: URLError(.notConnectedToInternet))
        await session.refresh()
        XCTAssertTrue(session.hasLoaded)
        XCTAssertEqual(session.snapshot.counts.first?.count, 3)
        XCTAssertNotNil(session.refreshError)
        XCTAssertNil(session.actionError)
        await service.configure(response: snapshot(4))
        await session.refresh()
        XCTAssertNil(session.refreshError)
        XCTAssertEqual(session.snapshot.counts.first?.count, 4)
    }

    @MainActor
    func testSuccessfulCommandIsNotReportedAsFailedWhenFollowupReadFails() async {
        let service = AdministrativeJobServiceStub()
        await service.configure(readError: URLError(.timedOut))
        let session = AdministrativeJobSession(service: service)
        await session.perform(.run(type: "scan-library"))
        XCTAssertNotNil(session.notice)
        XCTAssertNil(session.actionError)
        XCTAssertNotNil(session.refreshError)
        XCTAssertFalse(session.isMutating)
    }

    @MainActor
    func testOldPollCannotReplacePostCommandActivity() async {
        let service = AdministrativeJobServiceStub()
        let session = AdministrativeJobSession(service: service)
        await service.holdNextRead()
        let poll = Task { await session.refresh() }
        while !(await service.isReadHeld()) { await Task.yield() }
        await service.configure(response: snapshot(2))
        await session.perform(.clearFailures(type: nil))
        await service.finishHeldRead(snapshot(10))
        await poll.value
        XCTAssertEqual(session.snapshot.counts.first?.count, 2)
        XCTAssertFalse(session.isRefreshing)
    }

    @MainActor
    func testCommandIsNotResubmittedWhileItsRefreshIsPending() async {
        let service = AdministrativeJobServiceStub()
        let session = AdministrativeJobSession(service: service)
        await service.holdNextRead()
        let command = Task { await session.perform(.stop(type: nil)) }
        while !(await service.isReadHeld()) { await Task.yield() }
        await session.perform(.stop(type: nil))
        await service.finishHeldRead(snapshot(0))
        await command.value
        let count = await service.mutationCount
        XCTAssertEqual(count, 1)
    }

    @MainActor
    func testMutationRetryClearsPriorErrorAndReadCancellationStaysSilent() async {
        let service = AdministrativeJobServiceStub()
        let session = AdministrativeJobSession(service: service)
        await service.configure(mutationError: URLError(.timedOut))
        await session.perform(.cancel(id: UUID()))
        XCTAssertNotNil(session.actionError)
        XCTAssertNil(session.notice)
        await service.configure(readError: URLError(.cancelled))
        await session.perform(.cancel(id: UUID()))
        XCTAssertNil(session.actionError)
        XCTAssertNil(session.refreshError)
        XCTAssertNotNil(session.notice)
        XCTAssertFalse(session.isRefreshing)
    }

    private func snapshot(_ failures: Int) -> AdministrativeJobListResponse {
        .init(items: [], counts: [.init(type: "scan-library", status: "failed", count: failures)])
    }
}
