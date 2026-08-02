@preconcurrency import AVFoundation
import Foundation
import Observation

/// Page-view-owned presentation coordinator. Construction is deliberately inert.
/// Preparation and the user's request to begin playback are separate so a video
/// can warm in the background without autoplaying.
@Observable
@MainActor
final class VideoPlaybackPreparationCoordinator {
    private enum PreparationError: LocalizedError {
        case failed(String)
        var errorDescription: String? { if case .failed(let message) = self { message } else { nil } }
    }
    private(set) var phase: VideoPlaybackPreparationPhase = .idle
    /// True while a fullscreen presentation driven by this coordinator's owner
    /// is on screen. The owning page checks it before tearing playback down in
    /// `onDisappear`: presenting a fullscreen cover removes the presenting
    /// hierarchy on iOS, so the page "disappears" while its own player is up.
    var isFullscreenPresented = false
    private(set) var videoDetail: EntityDetail?
    private(set) var controller: VideoPlaybackController?
    private(set) var requestedResumeSeconds: Double?
    private(set) var playRequested = false
    private(set) var playbackStartOverrideSeconds: Double?

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
        #if DEBUG
            NSLog("VFS3 start requested phase=\(phase) coord=\(ObjectIdentifier(self))")
        #endif
        guard phase != .loading, phase != .ready else { return }
        let generation = beginLoading()
        preparationTask = Task { [weak self] in
            await self?.prepare(request, generation: generation)
        }
    }

    func requestPlayback(from startSeconds: Double? = nil) {
        playRequested = true
        playbackStartOverrideSeconds = startSeconds
        guard phase == .ready else { return }
        if let controller {
            beginRequestedPlayback(with: controller)
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

        #if DEBUG
            NSLog("VFS3 restoreActivePlayback beginLoading coord=\(ObjectIdentifier(self))")
        #endif
        let generation = beginLoading()
        preparationTask = Task { [weak self] in
            guard let self else { return }
            await settle(
                detail: active.detail,
                controller: active.controller,
                onPlaybackCompleted: onPlaybackCompleted,
                generation: generation
            )
        }
    }

    func waitUntilSettled() async {
        await preparationTask?.value
    }

    /// Adopts an already-loaded controller, e.g. when playback auto-advances to
    /// the next episode. The fullscreen player observes this coordinator, so the
    /// handoff must land here — swapping only view-local state leaves the player
    /// watching the stopped predecessor.
    func adopt(controller: VideoPlaybackController, videoDetail: EntityDetail) {
        self.controller = controller
        self.videoDetail = videoDetail
        phase = .ready
    }

    func lifecycleToken() -> VideoPlaybackLifecycleToken {
        VideoPlaybackLifecycleToken(generation: preparationGeneration)
    }

    func isCurrent(_ token: VideoPlaybackLifecycleToken) -> Bool {
        token.generation == preparationGeneration
    }

    func reset() {
        #if DEBUG
            NSLog("VFS3 reset gen=\(preparationGeneration + 1) coord=\(ObjectIdentifier(self))")
        #endif
        preparationGeneration += 1
        preparationTask?.cancel()
        preparationTask = nil
        phase = .idle
        videoDetail = nil
        controller = nil
        requestedResumeSeconds = nil
        playRequested = false
        playbackStartOverrideSeconds = nil
        isFullscreenPresented = false
    }

    private func beginLoading() -> Int {
        preparationGeneration += 1
        preparationTask?.cancel()
        phase = .loading
        videoDetail = nil
        controller = nil
        requestedResumeSeconds = nil
        playbackStartOverrideSeconds = nil
        return preparationGeneration
    }

    private func prepare(
        _ request: VideoPlaybackPreparationRequest,
        generation: Int
    ) async {
        do {
            #if DEBUG
                NSLog("VFS3 prepare begin gen=\(generation)")
            #endif
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
            #if DEBUG
                NSLog("VFS3 resolved id=\(resolved.id)")
            #endif
            let controller = await prepareController(
                resolved: resolved,
                resumeAt: resumeAt,
                request: request
            )
            #if DEBUG
                NSLog("VFS3 controller prepared error=\(controller.errorMessage ?? "nil")")
            #endif
            try Task.checkCancellation()
            if let message = controller.errorMessage {
                throw PreparationError.failed(message)
            }
            await settle(
                detail: resolved,
                controller: controller,
                onPlaybackCompleted: request.onPlaybackCompleted,
                generation: generation
            )
        } catch is CancellationError {
            guard generation == preparationGeneration else { return }
            phase = .idle
        } catch {
            guard generation == preparationGeneration else { return }
            NSLog("VFS3 prepare failure: \(error.localizedDescription)")
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
        onPlaybackCompleted: @escaping @MainActor (UUID) -> Void,
        generation: Int
    ) async {
        do {
            NSLog("VFS3 settle waiting readiness")
            try await readinessWaiter(controller)
            NSLog("VFS3 settle readiness done")
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
            NSLog("VFS3 phase ready")
            if playRequested { beginRequestedPlayback(with: controller) }
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

    private func beginRequestedPlayback(with controller: VideoPlaybackController) {
        guard let playbackStartOverrideSeconds else {
            controller.play()
            return
        }
        controller.seek(to: playbackStartOverrideSeconds) { _ in
            controller.play()
        }
    }

    private static func resumeSeconds(in detail: EntityDetail) -> Double? {
        detail.capabilities.compactMap { capability -> Double? in
            guard case .consumption(let playback) = capability else { return nil }
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
