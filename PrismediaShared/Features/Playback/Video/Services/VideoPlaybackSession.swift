import AVFoundation
import Observation
import SwiftUI

@Observable
@MainActor
final class VideoPlaybackSession {
    private(set) var activeController: VideoPlaybackController?
    private(set) var activeOwnerLink: EntityLink?
    private(set) var activeVideoDetail: EntityDetail?

    @ObservationIgnored
    var onRestoreNavigation: ((EntityLink) -> Void)?

    @ObservationIgnored
    private let service: any VideoPlaybackServicing
    @ObservationIgnored
    private let preferences: VideoPlaybackPreferences
    @ObservationIgnored
    private let pictureInPictureHandoff: VideoPictureInPictureHandoff
    @ObservationIgnored
    private let systemPlayback: VideoSystemPlaybackIntegration
    @ObservationIgnored
    private let displayCriteria: VideoDisplayCriteriaIntegration
    @ObservationIgnored
    private var activeVideoID: UUID?
    @ObservationIgnored
    private var activeRestoreLink: EntityLink?
    @ObservationIgnored
    private var loadTask: Task<Void, Never>?
    @ObservationIgnored
    private var restoreTask: Task<Void, Never>?
    @ObservationIgnored
    private var ownerIsVisible = false

    init(
        service: any VideoPlaybackServicing,
        preferences: VideoPlaybackPreferences = VideoPlaybackPreferences(),
        pictureInPictureHandoff: VideoPictureInPictureHandoff = .live,
        systemPlayback: VideoSystemPlaybackIntegration = .inactive,
        displayCriteria: VideoDisplayCriteriaIntegration = .inactive
    ) {
        self.service = service
        self.preferences = preferences
        self.pictureInPictureHandoff = pictureInPictureHandoff
        self.systemPlayback = systemPlayback
        self.displayCriteria = displayCriteria
    }

    func activate(
        ownerLink: EntityLink,
        restoreLink: EntityLink? = nil,
        videoDetail: EntityDetail,
        nowPlayingDetail: EntityDetail? = nil,
        resumeAt: Double,
        autoPlay: Bool = false
    ) -> VideoPlaybackController {
        let metadata = VideoNowPlayingMetadata(
            detail: nowPlayingDetail ?? videoDetail,
            ownerLink: ownerLink,
            playableDetail: videoDetail
        )
        if activeVideoID == videoDetail.id, let activeController {
            restoreTask?.cancel()
            restoreTask = nil
            activeOwnerLink = ownerLink
            activeRestoreLink = restoreLink ?? ownerLink
            activeVideoDetail = videoDetail
            ownerIsVisible = true
            systemPlayback.activate(activeController, metadata: metadata)
            return activeController
        }

        loadTask?.cancel()
        if let activeController { systemPlayback.deactivate(activeController) }
        activeController?.stopPictureInPicture()
        activeController?.stop()
        let controller = VideoPlaybackController(
            videoID: videoDetail.id,
            service: service,
            audioSession: SystemVideoAudioSession(),
            sidecarSubtitles: Self.subtitles(in: videoDetail),
            displayCriteria: displayCriteria,
            preferredEngine: preferences.engine
        )
        controller.pictureInPicture.onRestore = { [weak self] in
            guard let self, let restoreLink = self.activeRestoreLink else { return }
            self.onRestoreNavigation?(restoreLink)
            self.restoreTask?.cancel()
            self.restoreTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, let self, !self.ownerIsVisible else { return }
                self.reset()
            }
        }
        controller.pictureInPicture.onStoppedWithoutRestore = { [weak self, weak controller] in
            guard let self,
                let controller,
                self.activeController === controller,
                !self.ownerIsVisible
            else { return }
            self.reset()
        }
        controller.pictureInPicture.onFailedToStart = { [weak self, weak controller] in
            guard let self,
                let controller,
                self.activeController === controller,
                !self.ownerIsVisible
            else { return }
            self.reset()
        }
        activeVideoID = videoDetail.id
        activeOwnerLink = ownerLink
        activeRestoreLink = restoreLink ?? ownerLink
        activeVideoDetail = videoDetail
        activeController = controller
        ownerIsVisible = true
        systemPlayback.activate(controller, metadata: metadata)
        loadTask = Task {
            await controller.load(resumeAt: resumeAt)
            guard !Task.isCancelled, autoPlay else { return }
            controller.play()
        }
        return controller
    }

    /// Activates the page-owned session and awaits its single negotiation task.
    /// A prior failed activation is retried only after an explicit new request.
    func prepare(
        ownerLink: EntityLink,
        restoreLink: EntityLink? = nil,
        videoDetail: EntityDetail,
        nowPlayingDetail: EntityDetail? = nil,
        resumeAt: Double
    ) async -> VideoPlaybackController {
        let controller = activate(
            ownerLink: ownerLink,
            restoreLink: restoreLink,
            videoDetail: videoDetail,
            nowPlayingDetail: nowPlayingDetail,
            resumeAt: resumeAt
        )
        if controller.errorMessage != nil {
            let retryTask = Task { await controller.retryLoad(resumeAt: resumeAt) }
            loadTask = retryTask
            await retryTask.value
            return controller
        }
        await loadTask?.value
        return controller
    }

    /// Re-adopts playback when its page becomes visible again, including the
    /// navigation initiated by Picture in Picture restoration.
    func restoreActivePlayback(
        ownerLink: EntityLink
    ) -> (detail: EntityDetail, controller: VideoPlaybackController)? {
        guard activeOwnerLink == ownerLink,
            let activeVideoDetail,
            let activeController
        else { return nil }
        restoreTask?.cancel()
        restoreTask = nil
        ownerIsVisible = true
        return (activeVideoDetail, activeController)
    }

    func advance(
        from controller: VideoPlaybackController,
        to advancedLink: EntityLink,
        videoDetail: EntityDetail
    ) -> VideoPlaybackController? {
        guard activeController === controller else { return nil }
        return activate(
            ownerLink: advancedLink,
            restoreLink: advancedLink,
            videoDetail: videoDetail,
            resumeAt: 0,
            autoPlay: true
        )
    }

    func ownerDidDisappear(_ ownerLink: EntityLink) {
        guard ownerLink == activeOwnerLink else { return }
        ownerIsVisible = false
        inlinePlaybackWillNavigate()
        guard let controller = activeController,
            VideoPlaybackPageExitPolicy.shouldReleasePlayback(
                pictureInPictureIsActiveOrStarting: pictureInPictureHandoff.isActiveOrStarting(controller)
            )
        else { return }
        reset()
    }

    /// Requests PiP before a navigation mutation can remove the inline player layer.
    /// AppRouter can call this same seam once shell navigation moves out of the view.
    func inlinePlaybackWillNavigate() {
        guard let controller = activeController,
            !pictureInPictureHandoff.isActiveOrStarting(controller),
            pictureInPictureHandoff.shouldRequest(controller)
        else { return }
        pictureInPictureHandoff.request(controller)
    }

    func flushPlaybackProgress() {
        activeController?.flushPlaybackProgress()
    }

    func reset() {
        loadTask?.cancel()
        restoreTask?.cancel()
        restoreTask = nil
        if let activeController { systemPlayback.deactivate(activeController) }
        activeController?.stopPictureInPicture()
        activeController?.stop()
        activeController = nil
        activeOwnerLink = nil
        activeVideoDetail = nil
        activeRestoreLink = nil
        activeVideoID = nil
        ownerIsVisible = false
    }

    private static func subtitles(in detail: EntityDetail) -> [EntitySubtitle] {
        detail.capabilities.compactMap { capability -> [EntitySubtitle]? in
            guard case .subtitles(let subtitles) = capability else { return nil }
            return subtitles.items
        }.first ?? []
    }
}

extension EnvironmentValues {
    @Entry var videoPlaybackSession: VideoPlaybackSession?
}
