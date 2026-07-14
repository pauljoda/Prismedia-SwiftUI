@preconcurrency import AVFoundation
import Foundation
import Observation

/// Page-view-owned presentation coordinator. Construction is deliberately inert:
/// resolving a movie child, negotiating media, and creating AVPlayer state all
/// remain behind the explicit `start` command.
@Observable
@MainActor
final class VideoPlaybackPreparationCoordinator {
    private enum PreparationError: LocalizedError {
        case failed(String)
        var errorDescription: String? { if case .failed(let message) = self { message } else { nil } }
    }
    private(set) var phase: VideoPlaybackPreparationPhase = .idle
    private(set) var videoDetail: EntityDetail?
    private(set) var controller: VideoPlaybackController?
    private(set) var requestedResumeSeconds: Double?

    @ObservationIgnored
    private let controllerFactory: VideoPlaybackControllerFactory
    @ObservationIgnored
    private let readinessWaiter: VideoPlaybackReadinessWaiter
    @ObservationIgnored
    private var preparationTask: Task<Void, Never>?
    @ObservationIgnored
    private var preparationGeneration = 0

    init() {
        controllerFactory = .live
        readinessWaiter = .live
    }

    init(
        controllerFactory: VideoPlaybackControllerFactory,
        readinessWaiter: VideoPlaybackReadinessWaiter
    ) {
        self.controllerFactory = controllerFactory
        self.readinessWaiter = readinessWaiter
    }

    func start(_ request: VideoPlaybackPreparationRequest) {
        guard phase != .loading, phase != .ready else { return }
        let generation = beginLoading()
        preparationTask = Task { [weak self] in
            await self?.prepare(request, generation: generation)
        }
    }

    func restoreActivePlaybackIfNeeded(
        session: VideoPlaybackSession?,
        ownerLink: EntityLink,
        onPlaybackCompleted: @escaping @MainActor (UUID) -> Void
    ) {
        guard let session,
            let active = session.restoreActivePlayback(ownerLink: ownerLink)
        else { return }
        guard phase != .ready || controller !== active.controller else { return }
        guard phase != .loading else { return }

        let generation = beginLoading()
        preparationTask = Task { [weak self] in
            guard let self else { return }
            await settle(
                detail: active.detail,
                controller: active.controller,
                startsPlayback: false,
                onPlaybackCompleted: onPlaybackCompleted,
                generation: generation
            )
        }
    }

    func waitUntilSettled() async {
        await preparationTask?.value
    }

    func lifecycleToken() -> VideoPlaybackLifecycleToken {
        VideoPlaybackLifecycleToken(generation: preparationGeneration)
    }

    func isCurrent(_ token: VideoPlaybackLifecycleToken) -> Bool {
        token.generation == preparationGeneration
    }

    func reset() {
        preparationGeneration += 1
        preparationTask?.cancel()
        preparationTask = nil
        phase = .idle
        videoDetail = nil
        controller = nil
        requestedResumeSeconds = nil
    }

    private func beginLoading() -> Int {
        preparationGeneration += 1
        preparationTask?.cancel()
        phase = .loading
        videoDetail = nil
        controller = nil
        requestedResumeSeconds = nil
        return preparationGeneration
    }

    private func prepare(
        _ request: VideoPlaybackPreparationRequest,
        generation: Int
    ) async {
        do {
            let resolved = try await VideoEntityPlaybackStartup.resolve(
                detail: request.detail,
                sourceThumbnail: request.ownerLink.sourceThumbnail,
                detailLoader: request.detailLoader
            )
            try Task.checkCancellation()
            guard generation == preparationGeneration else { return }
            let resumeAt = Self.initialResumeSeconds(
                detail: resolved,
                ownerLink: request.ownerLink
            )
            requestedResumeSeconds = resumeAt
            let controller = await prepareController(
                resolved: resolved,
                resumeAt: resumeAt,
                request: request
            )
            try Task.checkCancellation()
            if let message = controller.errorMessage {
                throw PreparationError.failed(message)
            }
            await settle(
                detail: resolved,
                controller: controller,
                startsPlayback: true,
                onPlaybackCompleted: request.onPlaybackCompleted,
                generation: generation
            )
        } catch is CancellationError {
            guard generation == preparationGeneration else { return }
            phase = .idle
        } catch {
            guard generation == preparationGeneration else { return }
            phase = .failure(error.localizedDescription)
        }
    }

    private func prepareController(
        resolved: EntityDetail,
        resumeAt: Double,
        request: VideoPlaybackPreparationRequest
    ) async -> VideoPlaybackController {
        if let session = request.session {
            return await session.prepare(
                ownerLink: request.ownerLink,
                videoDetail: resolved,
                nowPlayingDetail: request.detail,
                resumeAt: resumeAt
            )
        }

        let controller = controllerFactory(
            videoID: resolved.id,
            service: request.playbackService,
            subtitles: Self.subtitles(in: resolved)
        )
        await controller.load(resumeAt: resumeAt)
        return controller
    }

    private func settle(
        detail: EntityDetail,
        controller: VideoPlaybackController,
        startsPlayback: Bool,
        onPlaybackCompleted: @escaping @MainActor (UUID) -> Void,
        generation: Int
    ) async {
        do {
            try await readinessWaiter(controller)
            try Task.checkCancellation()
            guard generation == preparationGeneration else { return }
            if let message = controller.errorMessage {
                throw PreparationError.failed(message)
            }
            controller.onPlaybackCompleted = { [resolvedID = detail.id] in
                onPlaybackCompleted(resolvedID)
            }
            videoDetail = detail
            self.controller = controller
            phase = .ready
            if startsPlayback { controller.play() }
        } catch is CancellationError {
            guard generation == preparationGeneration else { return }
            phase = .idle
        } catch {
            guard generation == preparationGeneration else { return }
            phase = .failure(error.localizedDescription)
        }
    }

    private static func initialResumeSeconds(
        detail: EntityDetail,
        ownerLink: EntityLink
    ) -> Double {
        VideoInitialResumePosition.resolve(
            detailResumeSeconds: resumeSeconds(in: detail),
            thumbnailResumeSeconds: ownerLink.thumbnailPreview?.resumeSeconds
        )
    }

    private static func resumeSeconds(in detail: EntityDetail) -> Double? {
        detail.capabilities.compactMap { capability -> Double? in
            guard case .playback(let playback) = capability else { return nil }
            return playback.resumeSeconds
        }.first
    }

    private static func subtitles(in detail: EntityDetail) -> [EntitySubtitle] {
        detail.capabilities.compactMap { capability -> [EntitySubtitle]? in
            guard case .subtitles(let subtitles) = capability else { return nil }
            return subtitles.items
        }.first ?? []
    }
}
