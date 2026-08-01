import XCTest

@testable import PrismediaCore

final class VideoProgressPlaybackRouteTests: XCTestCase {
    func testEpisodeProgressRoutesDirectlyThroughTheEpisodeEntity() throws {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episodeID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let episode = try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {
                  "id":"\(episodeID)",
                  "kind":"video-episode",
                  "title":"The Continue Episode",
                  "parentEntityId":"\(seasonID)",
                  "hasSourceMedia":true,
                  "capabilities":[
                    {"kind":"playable-video"},
                    {
                      "kind":"playback",
                      "playCount":2,
                      "skipCount":0,
                      "playDurationSeconds":1200,
                      "resumeSeconds":423,
                      "completedAt":null
                    },
                    {
                      "kind":"images",
                      "supportedKinds":[],
                      "items":[],
                      "thumbnailUrl":"/episodes/continue.jpg",
                      "thumbnail2xUrl":"/episodes/continue@2x.jpg"
                    }
                  ],
                  "childrenByKind":[],
                  "relationships":[]
                }
                """.utf8
            )
        )

        let route = try XCTUnwrap(VideoProgressPlaybackRoute.link(for: episode))

        XCTAssertEqual(route.intent, .playback)
        XCTAssertEqual(route.entityID, episodeID)
        XCTAssertEqual(route.kind, .videoEpisode)
        XCTAssertEqual(route.parentEntityID, seasonID)
        XCTAssertEqual(route.parentKind, .videoSeason)
        XCTAssertEqual(route.sourceThumbnail?.id, episodeID)
        XCTAssertEqual(route.thumbnailPreview?.resumeSeconds, 423)
        XCTAssertEqual(route.thumbnailPreview?.artworkPath, "/episodes/continue@2x.jpg")
        XCTAssertTrue(VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(for: route.intent))
        XCTAssertEqual(VideoPlaybackLaunchPolicy.presentationMode(for: route), .fullscreenOnly)
    }
}
