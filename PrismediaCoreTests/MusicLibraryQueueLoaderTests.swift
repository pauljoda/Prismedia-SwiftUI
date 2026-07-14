import XCTest

@testable import PrismediaCore

final class MusicLibraryQueueLoaderTests: XCTestCase {
    func testAllTracksBuildsACompleteMetadataRichQueueWithoutDetailRequests() async throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let albumID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let artistID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(trackID)","kind":"audio-track","title":"Shots","parentEntityId":"\#(albumID)","meta":[{"icon":"duration","label":"03:52"}]}],"nextCursor":null,"totalCount":1}"#
            ),
            .json(
                #"{"items":[{"id":"\#(albumID)","kind":"audio-library","title":"Smoke + Mirrors","parentEntityId":"\#(artistID)","coverUrl":"/assets/smoke.jpg"}]}"#
            ),
            .json(#"{"items":[{"id":"\#(artistID)","kind":"music-artist","title":"Imagine Dragons"}]}"#),
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let tracks = try await MusicLibraryQueueLoader(client: client).allTracks()

        XCTAssertEqual(tracks.map(\.title), ["Shots"])
        XCTAssertEqual(tracks.first?.album, "Smoke + Mirrors")
        XCTAssertEqual(tracks.first?.artist, "Imagine Dragons")
        XCTAssertEqual(tracks.first?.artworkPath, "/assets/smoke.jpg")
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            [
                "/api/entities",
                "/api/entities/thumbnails",
                "/api/entities/thumbnails",
            ])
    }

    func testFilteredTrackQueueUsesTheVisibleSortFiltersAndSearch() async throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(trackID)","kind":"audio-track","title":"Favorite"}],"nextCursor":null,"totalCount":1}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )
        let query = EntityListQuery(
            kind: .audioTrack,
            sort: "rating",
            sortDescending: true,
            favorite: true,
            ratingMin: 4
        )

        let tracks = try await MusicLibraryQueueLoader(client: client).tracks(
            matching: query,
            search: "favorite"
        )

        XCTAssertEqual(tracks.map(\.id), [trackID])
        let components = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(loader.requests.first?.url), resolvingAgainstBaseURL: false)
        )
        let values = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )
        XCTAssertEqual(values["sort"], "rating")
        XCTAssertEqual(values["sortDir"], "desc")
        XCTAssertEqual(values["favorite"], "true")
        XCTAssertEqual(values["ratingMin"], "4")
        XCTAssertEqual(values["query"], "favorite")
    }
}
