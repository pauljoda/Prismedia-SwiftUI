import XCTest

@testable import PrismediaCore

final class MusicLibraryQueueLoaderTests: XCTestCase {
    func testAllTracksBuildsALightweightQueueWithoutParentHydrationRequests() async throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let albumID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(trackID)","kind":"audio-track","title":"Shots","parentEntityId":"\#(albumID)","coverThumb2xUrl":"/assets/shots@2x.jpg","meta":[{"icon":"duration","label":"03:52"}]}],"nextCursor":null,"totalCount":1}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let tracks = try await MusicLibraryQueueLoader(client: client).allTracks()

        XCTAssertEqual(tracks.map(\.title), ["Shots"])
        XCTAssertNil(tracks.first?.album)
        XCTAssertNil(tracks.first?.artist)
        XCTAssertEqual(tracks.first?.artworkPath, "/assets/shots@2x.jpg")
        XCTAssertEqual(loader.requests.map { $0.url?.path }, ["/api/entities"])
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
