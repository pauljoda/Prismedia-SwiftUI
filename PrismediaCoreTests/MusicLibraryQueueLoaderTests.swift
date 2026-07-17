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

    func testShuffledTrackBatchesYieldRandomizedPagesWithoutWaitingForTheWholeLibrary() async throws {
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(firstID)","kind":"audio-track","title":"First"}],"nextCursor":"page-2","totalCount":2}"#
            ),
            .json(
                #"{"items":[{"id":"\#(secondID)","kind":"audio-track","title":"Second"}],"nextCursor":null,"totalCount":2}"#
            ),
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )
        let queueLoader = MusicLibraryQueueLoader(client: client)
        var batches: [[MusicTrack]] = []

        for try await batch in queueLoader.shuffledTrackBatches(
            matching: EntityListQuery(kind: .audioTrack, favorite: true),
            search: "mix",
            pageSize: 1,
            seed: 42
        ) {
            batches.append(batch)
        }

        XCTAssertEqual(batches.map { $0.map(\.id) }, [[firstID], [secondID]])
        XCTAssertEqual(loader.requests.count, 2)
        let requestValues = try loader.requests.map { request in
            let url = try XCTUnwrap(request.url)
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            return Dictionary(
                uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                    item.value.map { (item.name, $0) }
                }
            )
        }
        XCTAssertEqual(requestValues[0]["sort"], "random")
        XCTAssertEqual(requestValues[0]["seed"], "42")
        XCTAssertEqual(requestValues[0]["favorite"], "true")
        XCTAssertEqual(requestValues[0]["query"], "mix")
        XCTAssertNil(requestValues[0]["cursor"])
        XCTAssertEqual(requestValues[1]["cursor"], "page-2")
    }

    func testShuffledAlbumLibraryYieldsTracksFromTheFirstRandomAlbum() async throws {
        let albumID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let trackID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(albumID)","kind":"audio-library","title":"Random Album"}],"nextCursor":null,"totalCount":1}"#
            ),
            .json(
                #"{"id":"\#(albumID)","kind":"audio-library","title":"Random Album","hasSourceMedia":true,"capabilities":[],"relationships":[],"childrenByKind":[{"kind":"audio-track","label":"Tracks","entities":[{"id":"\#(trackID)","kind":"audio-track","title":"Random Song","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}]}]}"#
            ),
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )
        var tracks: [MusicTrack] = []

        for try await batch in MusicLibraryQueueLoader(client: client).shuffledTrackBatches(
            matching: EntityListQuery(kind: .audioLibrary),
            search: nil,
            seed: 42
        ) {
            tracks += batch
        }

        XCTAssertEqual(tracks.map(\.id), [trackID])
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            ["/api/entities", "/api/entities/\(albumID.uuidString.lowercased())"]
        )
    }
}
