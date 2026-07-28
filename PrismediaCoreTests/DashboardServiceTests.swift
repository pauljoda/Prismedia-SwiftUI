import XCTest

@testable import PrismediaCore

final class DashboardServiceTests: XCTestCase {
    @MainActor
    func testOneFailedShelfDoesNotDiscardSuccessfulDashboardContent() async {
        let video = item(5, kind: .video, title: "Feature")
        let loader = DashboardLoaderStub(responses: [
            DashboardCatalog.section(for: .video)!.query: .success(EntityListResponse(items: [video])),
            DashboardCatalog.section(for: .movie)!.query: .failure(.unavailable),
        ])
        let service = DashboardService(loader: loader)

        let snapshot = await service.load()

        XCTAssertEqual(snapshot.sections.first { $0.kind == .video }?.items, [video])
        XCTAssertEqual(snapshot.state, .content)
    }

}

private enum DashboardStubError: Error { case unavailable }

private actor DashboardLoaderStub: DashboardLoading {
    let responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>]

    init(responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>]) {
        self.responses = responses
    }

    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        try responses[query]?.get() ?? EntityListResponse(items: [])
    }
}

private func item(_ value: Int, kind: EntityKind, title: String) -> EntityThumbnail {
    EntityThumbnail(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!,
        kind: kind,
        title: title,
        hasSourceMedia: kind == .video || kind == .movie
    )
}
