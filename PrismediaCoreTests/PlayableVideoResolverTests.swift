import XCTest

@testable import PrismediaCore

final class PlayableVideoResolverTests: XCTestCase {
    func testStandaloneVideoResolvesItself() throws {
        let detail = try decodeDetail(kind: "video", children: "[]")

        XCTAssertEqual(PlayableVideoResolver.videoID(in: detail), detail.id)
    }

    func testMovieResolvesItsOwnedVideoChild() throws {
        let childID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let detail = try decodeDetail(
            kind: "movie",
            children: """
                [{"kind":"video","label":"Videos","entities":[{"id":"\(childID)","kind":"video","title":"Feature"}]}]
                """
        )

        XCTAssertEqual(PlayableVideoResolver.videoID(in: detail), childID)
    }

    func testFilelessMovieHasNoPlayableVideo() throws {
        let detail = try decodeDetail(kind: "movie", children: "[]")

        XCTAssertNil(PlayableVideoResolver.videoID(in: detail))
    }

    func testSeasonPlaybackResolvesTheRouteEpisodeInsteadOfAnArbitraryChild() throws {
        let season = try decodeDetail(kind: "video-season", children: "[]")
        let episodeID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let source = EntityThumbnail(
            id: episodeID,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: season.id,
            parentKind: .videoSeason
        )

        XCTAssertEqual(
            PlayableVideoResolver.videoID(in: season, sourceThumbnail: source),
            episodeID
        )
    }

    func testSeasonPlaybackRejectsAnUnrelatedRouteEpisode() throws {
        let season = try decodeDetail(kind: "video-season", children: "[]")
        let source = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Wrong Season",
            parentEntityID: UUID(),
            parentKind: .videoSeason
        )

        XCTAssertNil(PlayableVideoResolver.videoID(in: season, sourceThumbnail: source))
    }

    private func decodeDetail(kind: String, children: String) throws -> EntityDetail {
        let json = """
            {
              "id":"11111111-1111-1111-1111-111111111111",
              "kind":"\(kind)",
              "title":"Feature",
              "hasSourceMedia":true,
              "capabilities":[],
              "childrenByKind":\(children),
              "relationships":[]
            }
            """
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
    }
}
