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

    func testSearchTrackQueueDefensivelyExcludesWantedResults() async throws {
        let playableID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let wantedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(playableID)","kind":"audio-track","title":"Playable"},{"id":"\#(wantedID)","kind":"audio-track","title":"Wanted","isWanted":true}],"nextCursor":null,"totalCount":2}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let tracks = try await MusicLibraryQueueLoader(client: client).tracks(
            matching: EntityListQuery(kind: .audioTrack),
            search: "track"
        )

        XCTAssertEqual(tracks.map(\.id), [playableID])
    }

    func testArtistAlbumExpansionExcludesWantedTrackChildren() async throws {
        let albumID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let playableID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1")!
        let wantedID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2")!
        let album = EntityThumbnail(id: albumID, kind: .audioLibrary, title: "Album")
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"id":"\#(albumID)","kind":"audio-library","title":"Album","hasSourceMedia":true,"capabilities":[],"relationships":[],"childrenByKind":[{"kind":"audio-track","label":"Tracks","entities":[{"id":"\#(playableID)","kind":"audio-track","title":"Playable","sortOrder":1},{"id":"\#(wantedID)","kind":"audio-track","title":"Wanted","sortOrder":2,"isWanted":true}]}]}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let tracks = try await MusicLibraryQueueLoader(client: client).tracks(
            in: [album],
            artist: "Artist"
        )

        XCTAssertEqual(tracks.map(\.id), [playableID])
        XCTAssertEqual(tracks.map(\.artist), ["Artist"])
    }

    func testShuffledTrackBatchesYieldRandomizedPagesWithoutWaitingForTheWholeLibrary() async throws {
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let firstAlbumID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let secondAlbumID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let artistID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(firstID)","kind":"audio-track","title":"First","parentEntityId":"\#(firstAlbumID)"}],"nextCursor":"page-2","totalCount":2}"#
            ),
            .json(
                #"{"items":[{"id":"\#(firstAlbumID)","kind":"audio-library","title":"First Album","parentEntityId":"\#(artistID)"}]}"#
            ),
            .json(
                #"{"items":[{"id":"\#(artistID)","kind":"music-artist","title":"Test Artist"}]}"#
            ),
            .json(
                #"{"items":[{"id":"\#(secondID)","kind":"audio-track","title":"Second","parentEntityId":"\#(secondAlbumID)"}],"nextCursor":null,"totalCount":2}"#
            ),
            .json(
                #"{"items":[{"id":"\#(secondAlbumID)","kind":"audio-library","title":"Second Album","parentEntityId":"\#(artistID)"}]}"#
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
        XCTAssertEqual(batches.flatMap { $0 }.map(\.artist), ["Test Artist", "Test Artist"])
        XCTAssertEqual(batches.flatMap { $0 }.map(\.album), ["First Album", "Second Album"])
        XCTAssertEqual(loader.requests.count, 5)
        let listRequestValues = try [loader.requests[0], loader.requests[3]].map { request in
            let url = try XCTUnwrap(request.url)
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            return Dictionary(
                uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                    item.value.map { (item.name, $0) }
                }
            )
        }
        XCTAssertEqual(listRequestValues[0]["sort"], "random")
        XCTAssertEqual(listRequestValues[0]["seed"], "42")
        XCTAssertEqual(listRequestValues[0]["favorite"], "true")
        XCTAssertEqual(listRequestValues[0]["query"], "mix")
        XCTAssertNil(listRequestValues[0]["cursor"])
        XCTAssertEqual(listRequestValues[1]["cursor"], "page-2")
    }

    func testShuffledAlbumLibraryYieldsTracksFromTheFirstRandomAlbum() async throws {
        let albumID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let trackID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let artistID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(albumID)","kind":"audio-library","title":"Random Album","parentEntityId":"\#(artistID)"}],"nextCursor":null,"totalCount":1}"#
            ),
            .json(
                #"{"items":[{"id":"\#(artistID)","kind":"music-artist","title":"Random Artist"}]}"#
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
        XCTAssertEqual(tracks.map(\.artist), ["Random Artist"])
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            [
                "/api/entities",
                "/api/entities/thumbnails",
                "/api/entities/\(albumID.uuidString.lowercased())",
            ]
        )
    }
}
