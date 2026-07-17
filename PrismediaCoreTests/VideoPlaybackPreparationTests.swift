import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackPreparationTests: XCTestCase {
    func testWarmDirectVideoStaysPausedUntilPlaybackIsRequested() async throws {
        let videoID = UUID(uuidString: "10101010-1010-1010-1010-101010101010")!
        let detail = try videoDetail(id: videoID, resumeSeconds: 42)
        let loader = DeferredPlaybackDetailLoader(result: detail)
        let service = DeferredPlaybackService(videoID: videoID)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: loader,
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        XCTAssertEqual(preparation.phase, .idle)
        let initialLoadCount = await loader.loadCount
        let initialNegotiationCount = await service.directNegotiationCount
        XCTAssertEqual(initialLoadCount, 0)
        XCTAssertEqual(factory.creationCount, 0)
        XCTAssertEqual(initialNegotiationCount, 0)

        preparation.start(request)
        preparation.start(request)

        XCTAssertEqual(preparation.phase, .loading)
        await waitUntil { await service.directNegotiationCount == 1 }
        let preparedLoadCount = await loader.loadCount
        let preparedNegotiationCount = await service.directNegotiationCount
        XCTAssertEqual(preparedLoadCount, 0)
        XCTAssertEqual(factory.creationCount, 1)
        XCTAssertEqual(preparedNegotiationCount, 1)

        await readiness.open()
        await preparation.waitUntilSettled()

        XCTAssertEqual(preparation.phase, .ready)
        let settledNegotiationCount = await service.directNegotiationCount
        XCTAssertEqual(settledNegotiationCount, 1)
        XCTAssertEqual(preparation.videoDetail?.id, videoID)
        XCTAssertNotNil(preparation.controller)
        XCTAssertFalse(preparation.playRequested)
        XCTAssertEqual(preparation.controller?.player.rate, 0)

        preparation.requestPlayback()

        XCTAssertTrue(preparation.playRequested)
    }

    func testPageOwnedSessionWarmActivatesOneControllerWithoutRequestingPlayback() async throws {
        let videoID = UUID(uuidString: "11111111-1212-1212-1212-111111111111")!
        let detail = try videoDetail(id: videoID)
        let service = DeferredPlaybackService(videoID: videoID)
        let session = VideoPlaybackSession(service: service)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: DeferredPlaybackDetailLoader(result: detail),
            playbackService: service,
            session: session,
            onPlaybackCompleted: { _ in }
        )

        let initialNegotiationCount = await service.directNegotiationCount
        XCTAssertNil(session.activeController)
        XCTAssertEqual(initialNegotiationCount, 0)

        preparation.start(request)
        XCTAssertEqual(preparation.phase, .loading)
        await waitUntil { await service.directNegotiationCount == 1 }

        XCTAssertNotNil(session.activeController)
        let preparedNegotiationCount = await service.directNegotiationCount
        XCTAssertEqual(preparedNegotiationCount, 1)

        await readiness.open()
        await preparation.waitUntilSettled()
        XCTAssertEqual(preparation.phase, .ready)
        XCTAssertTrue(preparation.controller === session.activeController)
        XCTAssertFalse(preparation.playRequested)
        XCTAssertEqual(preparation.controller?.player.rate, 0)
    }

    func testPlaybackRequestedDuringWarmStartsWhenPreparationSettles() async throws {
        let videoID = UUID(uuidString: "12121212-1212-1212-1212-121212121212")!
        let detail = try videoDetail(id: videoID)
        let service = DeferredPlaybackService(videoID: videoID)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: DeferredPlaybackDetailLoader(result: detail),
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        preparation.start(request)
        await waitUntil { await service.directNegotiationCount == 1 }
        preparation.requestPlayback()

        XCTAssertTrue(preparation.playRequested)
        XCTAssertEqual(preparation.phase, .loading)

        await readiness.open()
        await preparation.waitUntilSettled()

        XCTAssertEqual(preparation.phase, .ready)
        XCTAssertTrue(preparation.playRequested)
        XCTAssertEqual(preparation.controller?.hasRequestedPlayback, true)
    }

    func testStartOverOverridesPreparedResumePositionBeforePlaybackBegins() async throws {
        let videoID = UUID(uuidString: "13131313-1313-1313-1313-131313131313")!
        let detail = try videoDetail(id: videoID, resumeSeconds: 84)
        let service = DeferredPlaybackService(videoID: videoID)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: DeferredPlaybackDetailLoader(result: detail),
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        preparation.start(request)
        await waitUntil { await service.directNegotiationCount == 1 }
        preparation.requestPlayback(from: 0)
        await readiness.open()
        await preparation.waitUntilSettled()

        XCTAssertEqual(preparation.requestedResumeSeconds, 84)
        XCTAssertEqual(preparation.playbackStartOverrideSeconds, 0)
        XCTAssertEqual(preparation.controller?.currentTime, 0)
        XCTAssertTrue(preparation.playRequested)
    }

    func testPreparationFailureIsObservableAndRetryStartsOneNewNegotiation() async throws {
        let videoID = UUID(uuidString: "20202020-2020-2020-2020-202020202020")!
        let detail = try videoDetail(id: videoID)
        let service = DeferredPlaybackService(
            videoID: videoID,
            error: DeferredPlaybackTestError.negotiationFailed
        )
        let factory = DeferredPlaybackControllerFactorySpy()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in XCTFail("Failed negotiation must not wait for readiness") }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: DeferredPlaybackDetailLoader(result: detail),
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        preparation.start(request)
        XCTAssertEqual(preparation.phase, .loading)
        await preparation.waitUntilSettled()

        XCTAssertEqual(preparation.phase, .failure("Playback negotiation failed."))
        XCTAssertNil(preparation.controller)

        preparation.start(request)
        XCTAssertEqual(preparation.phase, .loading)
        await preparation.waitUntilSettled()

        let negotiationCount = await service.directNegotiationCount
        XCTAssertEqual(negotiationCount, 2)
        XCTAssertEqual(preparation.phase, .failure("Playback negotiation failed."))
    }

    func testMoviePreparationResolvesPlayableChildBeforeNegotiatingAndPrefersItsResumePosition() async throws {
        let movieID = UUID(uuidString: "30303030-3030-3030-3030-303030303030")!
        let videoID = UUID(uuidString: "31313131-3131-3131-3131-313131313131")!
        let movie = try movieDetail(id: movieID, videoID: videoID)
        let video = try videoDetail(id: videoID, resumeSeconds: 96)
        let loader = DeferredPlaybackDetailLoader(result: video)
        let service = DeferredPlaybackService(videoID: videoID)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: movie,
            ownerLink: EntityLink(
                entityID: movieID,
                kind: .movie,
                thumbnailPreview: .init(
                    title: "Feature",
                    subtitle: nil,
                    artworkPath: "/feature.jpg",
                    resumeSeconds: 12
                )
            ),
            detailLoader: loader,
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        preparation.start(request)
        await waitUntil { await service.directNegotiationCount == 1 }

        let loadedIDs = await loader.loadedIDs
        let negotiatedVideoIDs = await service.directNegotiatedVideoIDs
        XCTAssertEqual(loadedIDs, [videoID])
        XCTAssertEqual(negotiatedVideoIDs, [videoID])
        XCTAssertEqual(preparation.requestedResumeSeconds, 96)

        await readiness.open()
        await preparation.waitUntilSettled()
        XCTAssertEqual(preparation.phase, .ready)
    }

    func testResetForAnotherDetailCancelsPreparationAndClearsOwnedPlaybackState() async throws {
        let videoID = UUID(uuidString: "40404040-4040-4040-4040-404040404040")!
        let detail = try videoDetail(id: videoID)
        let service = DeferredPlaybackService(videoID: videoID)
        let factory = DeferredPlaybackControllerFactorySpy()
        let readiness = DeferredPlaybackReadinessGate()
        let preparation = VideoPlaybackPreparationCoordinator(
            controllerFactory: factory.factory,
            readinessWaiter: .init { _ in await readiness.wait() }
        )
        let request = VideoPlaybackPreparationRequest(
            detail: detail,
            ownerLink: EntityLink(entityID: videoID, kind: .video),
            detailLoader: DeferredPlaybackDetailLoader(result: detail),
            playbackService: service,
            session: nil,
            onPlaybackCompleted: { _ in }
        )

        preparation.start(request)
        await waitUntil { await service.directNegotiationCount == 1 }

        preparation.reset()
        await readiness.open()
        try? await Task.sleep(for: .milliseconds(10))

        XCTAssertEqual(preparation.phase, .idle)
        XCTAssertNil(preparation.videoDetail)
        XCTAssertNil(preparation.controller)
        XCTAssertNil(preparation.requestedResumeSeconds)
        XCTAssertFalse(preparation.playRequested)
    }

    private func videoDetail(id: UUID, resumeSeconds: Double? = nil) throws -> EntityDetail {
        let capabilities =
            resumeSeconds.map {
                """
                [{"kind":"playback","playCount":0,"skipCount":0,"playDurationSeconds":0,"resumeSeconds":\($0)}]
                """
            } ?? "[]"
        return try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"video","title":"Playable","hasSourceMedia":true,"capabilities":\(capabilities),"childrenByKind":[],"relationships":[]}
                """.utf8))
    }

    private func movieDetail(id: UUID, videoID: UUID) throws -> EntityDetail {
        try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"movie","title":"Feature","hasSourceMedia":true,"capabilities":[],"childrenByKind":[{"kind":"video","label":"Videos","entities":[{"id":"\(videoID.uuidString)","kind":"video","title":"Playable"}]}],"relationships":[]}
                """.utf8))
    }

    private func waitUntil(
        _ condition: @escaping @Sendable () async -> Bool
    ) async {
        for _ in 0..<200 {
            if await condition() { return }
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Condition was not satisfied before timeout")
    }
}

private actor DeferredPlaybackDetailLoader: EntityDetailLoading {
    private(set) var loadedIDs: [UUID] = []
    var loadCount: Int { loadedIDs.count }
    private let result: EntityDetail

    init(result: EntityDetail) {
        self.result = result
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        loadedIDs.append(id)
        return result
    }
}

private actor DeferredPlaybackService: VideoPlaybackServicing {
    private(set) var negotiatedVideoIDs: [UUID] = []
    var negotiationCount: Int { negotiatedVideoIDs.count }
    private(set) var directNegotiatedVideoIDs: [UUID] = []
    var directNegotiationCount: Int { directNegotiatedVideoIDs.count }
    private let videoID: UUID
    private let error: DeferredPlaybackTestError?

    init(videoID: UUID, error: DeferredPlaybackTestError? = nil) {
        self.videoID = videoID
        self.error = error
    }

    func negotiateVideoPlayback(videoID: UUID, forceTranscode: Bool) async throws -> VideoPlaybackPlan {
        negotiatedVideoIDs.append(videoID)
        if !forceTranscode { directNegotiatedVideoIDs.append(videoID) }
        if let error { throw error }
        return VideoPlaybackPlan(
            videoID: self.videoID,
            url: URL(string: "https://media.example.test/video.mp4")!,
            delivery: .direct,
            playSessionID: "deferred",
            mediaSourceID: "source",
            durationSeconds: 120
        )
    }

    func mediaData(for path: String) async throws -> Data { Data() }
    nonisolated func authenticatedMediaURL(for path: String) -> URL? { URL(string: path) }
}

@MainActor
private final class DeferredPlaybackControllerFactorySpy {
    private(set) var creationCount = 0

    var factory: VideoPlaybackControllerFactory {
        VideoPlaybackControllerFactory { [weak self] videoID, service, subtitles in
            self?.creationCount += 1
            return VideoPlaybackController(
                videoID: videoID,
                service: service,
                audioSession: DeferredPlaybackAudioSession(),
                sidecarSubtitles: subtitles
            )
        }
    }
}

private struct DeferredPlaybackAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {}
}

private actor DeferredPlaybackReadinessGate {
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

private enum DeferredPlaybackTestError: LocalizedError {
    case negotiationFailed

    var errorDescription: String? { "Playback negotiation failed." }
}
