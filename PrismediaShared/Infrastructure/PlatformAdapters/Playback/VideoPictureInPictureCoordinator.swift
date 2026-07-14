import AVFoundation
import Combine
import Foundation
import Observation

#if canImport(UIKit)
    import AVKit

    @Observable
    @MainActor
    final class VideoPictureInPictureCoordinator: NSObject, AVPictureInPictureControllerDelegate {
        private(set) var isActive = false
        private(set) var isPossible = AVPictureInPictureController.isPictureInPictureSupported()

        @ObservationIgnored var onRestore: (() -> Void)?
        @ObservationIgnored var onStoppedWithoutRestore: (() -> Void)?
        @ObservationIgnored var onFailedToStart: (() -> Void)?
        var isActiveOrStarting: Bool { isActive || startRequested }

        @ObservationIgnored private var controller: AVPictureInPictureController?
        @ObservationIgnored private weak var playerLayer: AVPlayerLayer?
        @ObservationIgnored private var possibilityObservation: AnyCancellable?
        @ObservationIgnored private var pendingStart = false
        @ObservationIgnored private var startRequested = false
        @ObservationIgnored private var restoreRequested = false

        func attach(to layer: AVPlayerLayer) {
            guard !isActiveOrStarting, playerLayer !== layer else { return }
            playerLayer = layer
            guard let controller = AVPictureInPictureController(playerLayer: layer) else {
                isPossible = false
                return
            }
            controller.delegate = self
            #if os(iOS)
                controller.canStartPictureInPictureAutomaticallyFromInline = true
            #endif
            self.controller = controller
            isPossible = controller.isPictureInPicturePossible
            possibilityObservation = controller.publisher(for: \.isPictureInPicturePossible)
                .sink { [weak self, weak controller] possible in
                    guard let self else { return }
                    Task { @MainActor in
                        self.isPossible = possible
                        if possible, self.pendingStart, let controller {
                            self.pendingStart = false
                            controller.startPictureInPicture()
                        }
                    }
                }
        }

        func detach(from layer: AVPlayerLayer) {
            guard playerLayer === layer, !isActiveOrStarting else { return }
            layer.player = nil
            playerLayer = nil
            controller = nil
            possibilityObservation = nil
        }

        func start() {
            guard !isActive, !startRequested else { return }
            guard let controller else { return }
            startRequested = true
            guard controller.isPictureInPicturePossible else {
                pendingStart = true
                return
            }
            controller.startPictureInPicture()
        }

        func stop() {
            pendingStart = false
            startRequested = false
            controller?.stopPictureInPicture()
        }

        func pictureInPictureControllerDidStartPictureInPicture(
            _ pictureInPictureController: AVPictureInPictureController
        ) {
            isActive = true
        }

        func pictureInPictureControllerDidStopPictureInPicture(
            _ pictureInPictureController: AVPictureInPictureController
        ) {
            isActive = false
            startRequested = false
            let shouldReleaseOrphanedPlayback = !restoreRequested
            restoreRequested = false
            if shouldReleaseOrphanedPlayback { onStoppedWithoutRestore?() }
        }

        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            failedToStartPictureInPictureWithError error: Error
        ) {
            pendingStart = false
            startRequested = false
            onFailedToStart?()
        }

        func pictureInPictureController(
            _ pictureInPictureController: AVPictureInPictureController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
        ) {
            restoreRequested = true
            onRestore?()
            completionHandler(true)
        }
    }
#else
    @Observable
    @MainActor
    final class VideoPictureInPictureCoordinator {
        private(set) var isActive = false
        private(set) var isPossible = false
        @ObservationIgnored var onRestore: (() -> Void)?
        @ObservationIgnored var onStoppedWithoutRestore: (() -> Void)?
        @ObservationIgnored var onFailedToStart: (() -> Void)?
        var isActiveOrStarting: Bool { false }
        func attach(to layer: AVPlayerLayer) {}
        func detach(from layer: AVPlayerLayer) { layer.player = nil }
        func start() {}
        func stop() {}
    }
#endif
