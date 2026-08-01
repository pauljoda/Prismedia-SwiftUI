import XCTest

@testable import PrismediaCore

final class PlayableVideoResolverTests: XCTestCase {
    func testStandaloneVideoResolvesItself() throws {
        let detail = try decodeDetail(kind: "video", playable: true)

        XCTAssertEqual(PlayableVideoResolver.videoID(in: detail), detail.id)
    }

    func testMovieResolvesItselfThroughPlayableVideoCapability() throws {
        let detail = try decodeDetail(kind: "movie", playable: true)

        XCTAssertEqual(PlayableVideoResolver.videoID(in: detail), detail.id)
    }

    func testFilelessMovieHasNoPlayableVideo() throws {
        let detail = try decodeDetail(kind: "movie", playable: false)

        XCTAssertNil(PlayableVideoResolver.videoID(in: detail))
    }

    func testEpisodeResolvesItselfThroughPlayableVideoCapability() throws {
        let detail = try decodeDetail(kind: "video-episode", playable: true)

        XCTAssertEqual(PlayableVideoResolver.videoID(in: detail), detail.id)
    }

    func testSeasonPlaybackResolvesTheRouteEpisodeInsteadOfAnArbitraryChild() throws {
        let season = try decodeDetail(kind: "video-season", playable: false)
        let episodeID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let source = EntityThumbnail(
            id: episodeID,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: season.id,
            parentKind: .videoSeason,
            hasSourceMedia: true
        )

        XCTAssertEqual(
            PlayableVideoResolver.videoID(in: season, sourceThumbnail: source),
            episodeID
        )
    }

    func testSeasonPlaybackRejectsAnUnrelatedRouteEpisode() throws {
        let season = try decodeDetail(kind: "video-season", playable: false)
        let source = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Wrong Season",
            parentEntityID: UUID(),
            parentKind: .videoSeason,
            hasSourceMedia: true
        )

        XCTAssertNil(PlayableVideoResolver.videoID(in: season, sourceThumbnail: source))
    }

    private func decodeDetail(kind: String, playable: Bool) throws -> EntityDetail {
        let capabilities = playable ? #"[{"kind":"playable-video"}]"# : "[]"
        let json = """
            {
              "id":"11111111-1111-1111-1111-111111111111",
              "kind":"\(kind)",
              "title":"Feature",
              "hasSourceMedia":true,
              "capabilities":\(capabilities),
              "childrenByKind":[],
              "relationships":[]
            }
            """
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
    }
}
