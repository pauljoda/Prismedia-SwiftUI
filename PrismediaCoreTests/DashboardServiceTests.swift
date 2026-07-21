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

    @MainActor
    func testMovieOwnedVideosUseTheirParentPosterWhileStandaloneVideosKeepTheirArtwork() async {
        let movieID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let movieVideoID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let standaloneVideoID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let movieVideo = EntityThumbnail(
            id: movieVideoID,
            kind: .video,
            title: "Movie File",
            parentEntityID: movieID,
            parentKind: .movie,
            coverThumb2xURL: "/frames/movie-file@2x.jpg",
            hasSourceMedia: true,
            resumeSeconds: 120
        )
        let standaloneVideo = EntityThumbnail(
            id: standaloneVideoID,
            kind: .video,
            title: "Standalone Video",
            coverThumb2xURL: "/videos/standalone@2x.jpg",
            hasSourceMedia: true
        )
        let movie = EntityThumbnail(
            id: movieID,
            kind: .movie,
            title: "Feature Film",
            coverURL: "/posters/feature.jpg",
            coverThumb2xURL: "/posters/feature@2x.jpg"
        )
        let videoQuery = DashboardCatalog.section(for: .video)!.query
        let loader = DashboardLoaderStub(
            responses: [
                videoQuery: .success(EntityListResponse(items: [movieVideo, standaloneVideo]))
            ],
            thumbnailsByID: [movieID: movie]
        )

        let snapshot = await DashboardService(loader: loader).load()

        let videos = snapshot.sections.first { $0.kind == .video }?.items ?? []
        XCTAssertEqual(videos.map(\.id), [movieVideoID, standaloneVideoID])
        XCTAssertEqual(videos.map(\.bestCoverPath), [
            "/posters/feature@2x.jpg",
            "/videos/standalone@2x.jpg",
        ])
        XCTAssertEqual(videos.first?.resumeSeconds, 120)
        let requestedThumbnailIDs = await loader.requestedThumbnailIDs
        XCTAssertEqual(requestedThumbnailIDs, [[movieID]])
    }

}

private enum DashboardStubError: Error { case unavailable }

private actor DashboardLoaderStub: DashboardLoading {
    let responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>]
    let thumbnailsByID: [UUID: EntityThumbnail]
    private(set) var requestedThumbnailIDs: [[UUID]] = []

    init(
        responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>],
        thumbnailsByID: [UUID: EntityThumbnail] = [:]
    ) {
        self.responses = responses
        self.thumbnailsByID = thumbnailsByID
    }

    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        try responses[query]?.get() ?? EntityListResponse(items: [])
    }

    func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        requestedThumbnailIDs.append(ids)
        return ids.compactMap { thumbnailsByID[$0] }
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
