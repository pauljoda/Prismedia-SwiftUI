import AVFoundation
import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackSessionTests: XCTestCase {
    func testFreshDirectVideoResolutionActivatesPlaybackWithoutLoadingAnotherEntity() async throws {
        let service = SessionVideoPlaybackService()
        let session = VideoPlaybackSession(service: service)
        let videoID = UUID(uuidString: "10101010-1010-1010-1010-101010101010")!
        let detail = try detail(id: videoID, resumeSeconds: 42)
        let owner = EntityLink(entityID: videoID, kind: .video)
        let loader = UnexpectedEntityDetailLoader()

        let resolved = try await VideoEntityPlaybackStartup.prepare(
            detail: detail,
            ownerLink: owner,
            detailLoader: loader
        ) { resolvedDetail, resumeAt in
            _ = session.activate(
                ownerLink: owner,
                videoDetail: resolvedDetail,
                resumeAt: resumeAt
            )
        }

        XCTAssertEqual(resolved.id, videoID)
        XCTAssertEqual(session.activeOwnerLink, owner)
        XCTAssertNotNil(session.activeController)
        let loadCount = await loader.loadCount
        XCTAssertEqual(loadCount, 0)
    }

    func testReactivatingTheSameVideoReusesControllerAndNegotiatesOnce() async throws {
        let service = SessionVideoPlaybackService()
        let session = VideoPlaybackSession(service: service)
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let detail = try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(videoID.uuidString)","kind":"video","title":"Persistent Video","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
                """.utf8))
        let owner = EntityLink(entityID: videoID, kind: .video)

        let first = session.activate(ownerLink: owner, videoDetail: detail, resumeAt: 0)
        let second = session.activate(ownerLink: owner, videoDetail: detail, resumeAt: 0)
        try await Task.sleep(for: .milliseconds(40))
        let count = await service.directNegotiationCount

        XCTAssertTrue(first === second)
        XCTAssertEqual(count, 1)
    }

    func testActivationPublishesSystemPlaybackMetadataAndResetDeactivatesIt() throws {
        var activatedController: VideoPlaybackController?
        var activatedMetadata: VideoNowPlayingMetadata?
        var deactivatedController: VideoPlaybackController?
        let integration = VideoSystemPlaybackIntegration(
            activate: { controller, metadata in
                activatedController = controller
                activatedMetadata = metadata
            },
            deactivate: { controller in
                deactivatedController = controller
            }
        )
        let session = VideoPlaybackSession(
            service: SessionVideoPlaybackService(),
            systemPlayback: integration
        )
        let videoID = UUID(uuidString: "12121212-1212-1212-1212-121212121212")!
        let ownerID = UUID(uuidString: "13131313-1313-1313-1313-131313131313")!
        let videoDetail = try detail(id: videoID, title: "Playable Child")
        let ownerDetail = try detail(id: ownerID, title: "The Native Cut")
        let owner = EntityLink(
            entityID: ownerID,
            kind: .movie,
            thumbnailPreview: .init(
                title: "Library Title",
                subtitle: "Season 2, Episode 4",
                artworkPath: "/assets/native-cut.jpg"
            )
        )

        let controller = session.activate(
            ownerLink: owner,
            videoDetail: videoDetail,
            nowPlayingDetail: ownerDetail,
            resumeAt: 0
        )

        XCTAssertTrue(activatedController === controller)
        XCTAssertEqual(activatedMetadata?.contentID, ownerID)
        XCTAssertEqual(activatedMetadata?.title, "The Native Cut")
        XCTAssertEqual(activatedMetadata?.subtitle, "Season 2, Episode 4")
        XCTAssertEqual(activatedMetadata?.artworkPath, "/assets/native-cut.jpg")

        session.reset()

        XCTAssertTrue(deactivatedController === controller)
    }

    func testLeavingTheOwningDetailPageReleasesPlayback() throws {
        let session = VideoPlaybackSession(service: SessionVideoPlaybackService())
        let videoID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let detail = try detail(id: videoID)
        let owner = EntityLink(entityID: videoID, kind: .video)

        _ = session.activate(ownerLink: owner, videoDetail: detail, resumeAt: 0)
        session.ownerDidDisappear(owner)

        XCTAssertNil(session.activeController)
        XCTAssertNil(session.activeOwnerLink)
    }

    func testNavigationRequestsPictureInPictureOnceAndRetainsStartingPlayback() throws {
        let handoff = PictureInPictureHandoffSpy()
        let session = VideoPlaybackSession(
            service: SessionVideoPlaybackService(),
            pictureInPictureHandoff: handoff.adapter
        )
        let videoID = UUID(uuidString: "20202020-2020-2020-2020-202020202020")!
        let detail = try detail(id: videoID)
        let owner = EntityLink(entityID: videoID, kind: .video)
        let controller = session.activate(ownerLink: owner, videoDetail: detail, resumeAt: 0)

        session.inlinePlaybackWillNavigate()
        session.inlinePlaybackWillNavigate()
        session.ownerDidDisappear(owner)

        XCTAssertEqual(handoff.requestCount, 1)
        XCTAssertTrue(session.activeController === controller)
        XCTAssertEqual(session.activeOwnerLink, owner)
    }

    func testAnotherPageDisappearingCannotStopTheActiveOwner() throws {
        let session = VideoPlaybackSession(service: SessionVideoPlaybackService())
        let videoID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let detail = try detail(id: videoID)
        let owner = EntityLink(entityID: videoID, kind: .video)

        let controller = session.activate(ownerLink: owner, videoDetail: detail, resumeAt: 0)
        session.ownerDidDisappear(EntityLink(entityID: UUID(), kind: .video))

        XCTAssertTrue(session.activeController === controller)
        XCTAssertEqual(session.activeOwnerLink, owner)
    }

    func testAdvancedEpisodeIsUsedForPictureInPictureRestore() throws {
        let session = VideoPlaybackSession(service: SessionVideoPlaybackService())
        let firstID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let secondID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let firstOwner = EntityLink(entityID: firstID, kind: .video)
        let secondOwner = EntityLink(entityID: secondID, kind: .video)
        var restoredLink: EntityLink?
        session.onRestoreNavigation = { restoredLink = $0 }

        let controller = session.activate(
            ownerLink: firstOwner,
            restoreLink: secondOwner,
            videoDetail: try detail(id: secondID),
            resumeAt: 0
        )
        controller.pictureInPicture.onRestore?()

        XCTAssertEqual(restoredLink, secondOwner)
        XCTAssertEqual(session.activeOwnerLink, firstOwner)
    }

    func testAdvancingTransfersPlaybackOwnershipBeforePriorDetailDisappears() throws {
        let session = VideoPlaybackSession(service: SessionVideoPlaybackService())
        let firstID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let secondID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let firstLink = EntityLink(entityID: firstID, kind: .video)
        let secondLink = EntityLink(entityID: secondID, kind: .video)

        let firstController = session.activate(
            ownerLink: firstLink,
            videoDetail: try detail(id: firstID),
            resumeAt: 0
        )
        let advancedController = session.advance(
            from: firstController,
            to: secondLink,
            videoDetail: try detail(id: secondID)
        )
        session.ownerDidDisappear(firstLink)

        XCTAssertNotNil(advancedController)
        XCTAssertTrue(session.activeController === advancedController)
        XCTAssertEqual(session.activeOwnerLink, secondLink)
    }

    func testAdvancingSeasonPlaybackRetainsTheSeasonOwnerAndUpdatesItsEpisodeSource() throws {
        let session = VideoPlaybackSession(service: SessionVideoPlaybackService())
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let firstID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let secondID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let first = EntityThumbnail(
            id: firstID,
            kind: .video,
            title: "Episode One",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )
        let second = EntityThumbnail(
            id: secondID,
            kind: .video,
            title: "Episode Two",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )
        let firstOwner = EntityLink(thumbnail: first, intent: .playback)
        let secondOwner = EntityLink(thumbnail: second, intent: .playback)

        let firstController = session.activate(
            ownerLink: firstOwner,
            videoDetail: try detail(id: firstID),
            resumeAt: 0
        )
        let advancedController = session.advance(
            from: firstController,
            to: secondOwner,
            videoDetail: try detail(id: secondID)
        )

        XCTAssertNotNil(advancedController)
        XCTAssertEqual(session.activeOwnerLink?.entityID, seasonID)
        XCTAssertEqual(session.activeOwnerLink?.kind, .videoSeason)
        XCTAssertEqual(session.activeOwnerLink?.sourceThumbnail?.id, secondID)
    }

    func testRestoringTheActiveOwnerReusesItsPreparedDetailAndController() async throws {
        let service = SessionVideoPlaybackService()
        let session = VideoPlaybackSession(service: service)
        let videoID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        let detail = try detail(id: videoID)
        let owner = EntityLink(
            entityID: videoID,
            kind: .video,
            thumbnailPreview: .init(
                title: "Original",
                subtitle: nil,
                artworkPath: "/original.jpg"
            )
        )
        let controller = session.activate(
            ownerLink: owner,
            videoDetail: detail,
            resumeAt: 0
        )
        try await Task.sleep(for: .milliseconds(40))

        let refreshedOwner = EntityLink(
            entityID: videoID,
            kind: .video,
            thumbnailPreview: .init(
                title: "Refreshed",
                subtitle: nil,
                artworkPath: "/refreshed.jpg",
                progress: 0.5
            )
        )
        let restored = session.restoreActivePlayback(ownerLink: refreshedOwner)
        try await Task.sleep(for: .milliseconds(20))
        let directNegotiationCount = await service.directNegotiationCount

        XCTAssertTrue(restored?.controller === controller)
        XCTAssertEqual(restored?.detail, detail)
        XCTAssertEqual(directNegotiationCount, 1)
    }

    func testRetryAfterInstalledItemFailureReplacesItemAndNegotiatesAgain() async throws {
        let videoID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let detail = try detail(id: videoID)
        let owner = EntityLink(entityID: videoID, kind: .video)
        let service = RetryVideoPlaybackService()
        let session = VideoPlaybackSession(service: service)
        let controller = await session.prepare(
            ownerLink: owner,
            videoDetail: detail,
            resumeAt: 0
        )
        let failedItem = try XCTUnwrap(controller.player.currentItem)

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: failedItem,
            userInfo: [
                AVPlayerItemFailedToPlayToEndTimeErrorKey: RetryVideoPlaybackError.fallbackFailed
            ]
        )
        await waitUntil { controller.errorMessage != nil }

        XCTAssertTrue(controller.player.currentItem === failedItem)
        XCTAssertNotNil(controller.errorMessage)

        let retried = await session.prepare(
            ownerLink: owner,
            videoDetail: detail,
            resumeAt: 0
        )
        let directNegotiationCount = await service.directNegotiationCount

        XCTAssertTrue(retried === controller)
        XCTAssertFalse(retried.player.currentItem === failedItem)
        XCTAssertNil(retried.errorMessage)
        XCTAssertEqual(directNegotiationCount, 2)
    }

    private func detail(
        id: UUID,
        title: String = "Page-owned Video",
        resumeSeconds: Double? = nil
    ) throws -> EntityDetail {
        let capabilities =
            resumeSeconds.map { seconds in
                """
                [{"kind":"playback","playCount":0,"skipCount":0,"playDurationSeconds":0,"resumeSeconds":\(seconds)}]
                """
            } ?? "[]"
        return try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"video","title":"\(title)","hasSourceMedia":true,"capabilities":\(capabilities),"childrenByKind":[],"relationships":[]}
                """.utf8))
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Condition was not satisfied before timeout")
    }
}

@MainActor
private final class PictureInPictureHandoffSpy {
    private(set) var requestCount = 0
    private var isStarting = false

    var adapter: VideoPictureInPictureHandoff {
        VideoPictureInPictureHandoff(
            shouldRequest: { _ in true },
            isActiveOrStarting: { [weak self] _ in self?.isStarting == true },
            request: { [weak self] _ in
                guard let self else { return }
                requestCount += 1
                isStarting = true
            }
        )
    }
}

private actor UnexpectedEntityDetailLoader: EntityDetailLoading {
    private(set) var loadCount = 0

    func loadEntity(id: UUID) async throws -> EntityDetail {
        loadCount += 1
        throw UnexpectedEntityDetailLoadError.requested(id)
    }
}

private enum UnexpectedEntityDetailLoadError: Error {
    case requested(UUID)
}

private actor SessionVideoPlaybackService: VideoPlaybackServicing {
    private(set) var negotiationCount = 0
    private(set) var directNegotiationCount = 0

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        negotiationCount += 1
        if !forceTranscode { directNegotiationCount += 1 }
        return VideoPlaybackPlan(
            videoID: videoID,
            url: URL(string: "https://media.example.test/video.mp4")!,
            delivery: .direct,
            playSessionID: "session",
            mediaSourceID: "source",
            durationSeconds: 90
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}

private actor RetryVideoPlaybackService: VideoPlaybackServicing {
    private(set) var directNegotiationCount = 0

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        if forceTranscode { throw RetryVideoPlaybackError.fallbackFailed }
        directNegotiationCount += 1
        return VideoPlaybackPlan(
            videoID: videoID,
            url: URL(string: "http://192.0.2.1/video.mp4")!,
            delivery: .direct,
            playSessionID: "retry",
            mediaSourceID: "retry-source",
            durationSeconds: 90
        )
    }

    func negotiateVideoPlayback(
        videoID: UUID,
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int?
    ) async throws -> VideoPlaybackPlan {
        guard mode == .automatic else { throw RetryVideoPlaybackError.fallbackFailed }
        return try await negotiateVideoPlayback(videoID: videoID, forceTranscode: false)
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}

private enum RetryVideoPlaybackError: LocalizedError {
    case fallbackFailed

    var errorDescription: String? { "Fallback playback failed." }
}
