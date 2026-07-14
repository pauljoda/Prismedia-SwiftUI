import XCTest

@testable import PrismediaCore

@MainActor
final class EntityTranscriptTests: XCTestCase {
    private let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    func testNewTrackLoadRejectsTheOlderTracksLateResponse() {
        var state = EntityTranscriptState()
        let englishRequest = state.beginLoad(videoID: videoID, trackID: "english")
        let frenchRequest = state.beginLoad(videoID: videoID, trackID: "french")
        let englishCue = EntityTranscriptCue(id: 0, startTime: 1, endTime: 2, text: "Old result")
        let frenchCue = EntityTranscriptCue(id: 0, startTime: 3, endTime: 4, text: "Current result")

        state.finishLoad(.content([englishCue]), request: englishRequest)
        state.finishLoad(.content([frenchCue]), request: frenchRequest)

        XCTAssertEqual(state.selectedTrackID, "french")
        XCTAssertEqual(state.cues, [frenchCue])
    }

    func testSearchMatchesAllTermsWithoutCaseOrDiacriticSensitivity() {
        var state = EntityTranscriptState()
        let request = state.beginLoad(videoID: videoID, trackID: "english")
        state.finishLoad(
            .content([
                EntityTranscriptCue(id: 0, startTime: 1, endTime: 2, text: "A café beyond the SIGNAL"),
                EntityTranscriptCue(id: 1, startTime: 3, endTime: 4, text: "Only signal remains"),
            ]),
            request: request
        )

        state.searchText = "CAFE signal"

        XCTAssertEqual(state.filteredCues.map(\.id), [0])
    }

    func testActiveCueUsesTheCurrentPlaybackInterval() {
        var state = EntityTranscriptState()
        let request = state.beginLoad(videoID: videoID, trackID: "english")
        state.finishLoad(
            .content([
                EntityTranscriptCue(id: 0, startTime: 0, endTime: 2, text: "First"),
                EntityTranscriptCue(id: 1, startTime: 2, endTime: 4, text: "Second"),
            ]),
            request: request
        )

        XCTAssertEqual(state.activeCueID(at: 2.5), 1)
        XCTAssertNil(state.activeCueID(at: 5))
    }

    func testTranscriptServiceLoadsTheExistingSubtitleEndpointAndParsesCues() async throws {
        let source = """
            WEBVTT

            00:01.000 --> 00:03.000
            First cue
            """
        let loader = EntityTranscriptSourceLoaderSpy(result: .success(Data(source.utf8)))
        let service = EntityTranscriptService(sourceLoader: loader)

        let outcome = await service.load(videoID: videoID, trackID: "track-en")

        guard case .content(let cues) = outcome else {
            return XCTFail("Expected parsed transcript cues.")
        }
        XCTAssertEqual(cues, [EntityTranscriptCue(id: 0, startTime: 1, endTime: 3, text: "First cue")])
        let calls = await loader.recordedCalls()
        XCTAssertEqual(calls.map(\.videoID), [videoID])
        XCTAssertEqual(calls.map(\.trackID), ["track-en"])
    }

    func testTranscriptSourceUsesTheExistingVideoSubtitleEndpoint() async throws {
        let loader = MockHTTPDataLoader(responses: [.data(Data("WEBVTT\n\n".utf8))])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        _ = try await PrismediaEntityDetailLoader(client: client).loadTranscriptSource(
            videoID: videoID,
            trackID: "english commentary"
        )

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(
            request.url.flatMap {
                URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath
            },
            "/api/videos/\(videoID.uuidString.lowercased())/subtitles/english%20commentary"
        )
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testSeekRequiresTheVisibleDetailToOwnTheMatchingVideoController() {
        let detailID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let otherID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let owner = EntityLink(entityID: detailID, kind: .movie)

        XCTAssertTrue(
            EntityTranscriptSeekPolicy.canSeek(
                ownerLink: owner,
                resolvedVideoID: videoID,
                activeOwnerLink: owner,
                activeVideoID: videoID
            )
        )
        XCTAssertFalse(
            EntityTranscriptSeekPolicy.canSeek(
                ownerLink: owner,
                resolvedVideoID: videoID,
                activeOwnerLink: EntityLink(entityID: otherID, kind: .movie),
                activeVideoID: videoID
            )
        )
        XCTAssertFalse(
            EntityTranscriptSeekPolicy.canSeek(
                ownerLink: owner,
                resolvedVideoID: videoID,
                activeOwnerLink: owner,
                activeVideoID: otherID
            )
        )
    }
}
