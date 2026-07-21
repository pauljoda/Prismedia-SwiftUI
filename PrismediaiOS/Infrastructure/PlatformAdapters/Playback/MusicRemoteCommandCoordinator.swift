#if os(iOS)
    import Foundation
    import MediaPlayer
    import UIKit

    @MainActor
    final class MusicRemoteCommandCoordinator {
        private static let artworkMaximumPixelSize = 1_024

        private let controller: MusicPlayerController
        private let engine: AVPlayerAudioPlaybackEngine
        private let artworkURL: (String?) -> URL?
        private let nowPlayingSession: MPNowPlayingSession
        private var artworkTask: Task<Void, Never>?
        nonisolated(unsafe) private var commandTargets: [(command: MPRemoteCommand, target: Any)] = []
        private var publicationState = MusicNowPlayingPublicationState()
        private var lastProgressPublicationTime = -Double.greatestFiniteMagnitude

        init(
            controller: MusicPlayerController,
            engine: AVPlayerAudioPlaybackEngine,
            artworkURL: @escaping (String?) -> URL?
        ) {
            self.controller = controller
            self.engine = engine
            self.artworkURL = artworkURL
            nowPlayingSession = MPNowPlayingSession(players: [engine.player])
            nowPlayingSession.automaticallyPublishesNowPlayingInfo = false
            registerCommands()
            observePlayback()
        }

        deinit {
            artworkTask?.cancel()
            for registration in commandTargets {
                registration.command.removeTarget(registration.target)
            }
        }

        private func registerCommands() {
            let commands = nowPlayingSession.remoteCommandCenter
            register(commands.playCommand) { [weak controller] _ in
                Task { @MainActor in controller?.resume() }
                return .success
            }
            register(commands.pauseCommand) { [weak controller] _ in
                Task { @MainActor in controller?.pause() }
                return .success
            }
            register(commands.togglePlayPauseCommand) { [weak controller] _ in
                Task { @MainActor in
                    guard let controller else { return }
                    controller.isPlaying ? controller.pause() : controller.resume()
                }
                return .success
            }
            register(commands.nextTrackCommand) { [weak controller] _ in
                Task { @MainActor in controller?.skipToNext() }
                return .success
            }
            register(commands.previousTrackCommand) { [weak controller] _ in
                Task { @MainActor in controller?.skipToPrevious() }
                return .success
            }
            register(commands.changePlaybackPositionCommand) { [weak controller] event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                Task { @MainActor in controller?.seek(to: event.positionTime) }
                return .success
            }
        }

        private func register(
            _ command: MPRemoteCommand,
            handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
        ) {
            let target = command.addTarget(handler: handler)
            commandTargets.append((command, target))
        }

        private func observePlayback() {
            controller.onNowPlayingStateChanged = { [weak self] in
                self?.publishNowPlaying()
            }
            engine.onNowPlayingProgressChanged = { [weak self] in
                guard let self else { return }
                self.controller.updateElapsedTime(self.engine.elapsedTime)
                self.publishProgressIfNeeded()
            }

            publishNowPlaying()
        }

        private func publishProgressIfNeeded() {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastProgressPublicationTime >= 1 else { return }
            lastProgressPublicationTime = now
            publishNowPlaying()
        }

        private func publishNowPlaying() {
            guard let track = controller.currentTrack else {
                artworkTask?.cancel()
                artworkTask = nil
                publicationState.clear()
                nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = nil
                updateCommandAvailability()
                return
            }

            let requiresArtwork = publicationState.beginPublishing(trackID: track.id)
            let existingArtwork =
                requiresArtwork
                ? nil
                : nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork]
            var information: [String: Any] = [
                MPMediaItemPropertyTitle: track.title,
                MPMediaItemPropertyArtist: MusicPresentation.artist(track.artist),
                MPNowPlayingInfoPropertyElapsedPlaybackTime: engine.elapsedTime,
                MPNowPlayingInfoPropertyPlaybackRate: controller.isPlaying ? controller.playbackRate : 0,
                MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            ]
            if let existingArtwork { information[MPMediaItemPropertyArtwork] = existingArtwork }
            if let album = track.album { information[MPMediaItemPropertyAlbumTitle] = album }
            let duration = engine.duration > 0 ? engine.duration : track.duration
            if let duration { information[MPMediaItemPropertyPlaybackDuration] = duration }
            nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = information
            nowPlayingSession.becomeActiveIfPossible(completion: nil)

            if requiresArtwork || existingArtwork == nil { loadArtwork(for: track) }
            updateCommandAvailability()
        }

        private func loadArtwork(for track: MusicTrack) {
            artworkTask?.cancel()
            guard let url = artworkURL(track.artworkPath) else {
                artworkTask = nil
                return
            }
            artworkTask = Task { [weak self] in
                guard
                    let decodedImage = try? await RemoteArtworkPipeline.shared.image(
                        for: url,
                        maxPixelSize: Self.artworkMaximumPixelSize
                    ),
                    !Task.isCancelled
                else { return }
                self?.installArtwork(UIImage(cgImage: decodedImage), for: track.id)
            }
        }

        private func installArtwork(_ image: UIImage, for trackID: UUID) {
            guard controller.currentTrack?.id == trackID else { return }
            var information = nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo ?? [:]
            information[MPMediaItemPropertyArtwork] = Self.mediaItemArtwork(for: image)
            nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = information
        }

        /// MediaPlayer invokes this request handler on its own access queue. Build
        /// it outside MainActor isolation so the framework can call it safely.
        nonisolated private static func mediaItemArtwork(for image: UIImage) -> MPMediaItemArtwork {
            MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        private func updateCommandAvailability() {
            let commands = nowPlayingSession.remoteCommandCenter
            commands.nextTrackCommand.isEnabled = controller.queue.canGoNext
            commands.previousTrackCommand.isEnabled = controller.queue.canGoPrevious
            commands.changePlaybackPositionCommand.isEnabled = controller.currentTrack != nil
        }
    }
#endif
