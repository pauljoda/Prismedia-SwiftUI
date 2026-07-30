#if os(iOS) || os(macOS)
    import Foundation
    import MediaPlayer
    #if os(iOS)
        import UIKit
    #else
        import AppKit
    #endif

    @MainActor
    final class MusicRemoteCommandCoordinator {
        private static let artworkMaximumPixelSize = 1_024

        private let controller: MusicPlayerController
        private let engine: AVPlayerAudioPlaybackEngine
        private let artworkURL: (String?) -> URL?
        #if os(iOS)
            private let nowPlayingSession: MPNowPlayingSession
        #endif
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
            #if os(iOS)
                nowPlayingSession = MPNowPlayingSession(players: [engine.player])
                nowPlayingSession.automaticallyPublishesNowPlayingInfo = false
            #endif
            registerCommands()
            observePlayback()
        }

        deinit {
            artworkTask?.cancel()
            for registration in commandTargets {
                registration.command.removeTarget(registration.target)
            }
        }

        private var nowPlayingInfoCenter: MPNowPlayingInfoCenter {
            #if os(iOS)
                nowPlayingSession.nowPlayingInfoCenter
            #else
                MPNowPlayingInfoCenter.default()
            #endif
        }

        private var remoteCommandCenter: MPRemoteCommandCenter {
            #if os(iOS)
                nowPlayingSession.remoteCommandCenter
            #else
                MPRemoteCommandCenter.shared()
            #endif
        }

        private func registerCommands() {
            let commands = remoteCommandCenter
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
                guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
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
                self.controller.updatePlaybackProgress(
                    elapsedTime: self.engine.elapsedTime,
                    duration: self.engine.duration,
                    isAdvancing: self.engine.isPlaybackAdvancing
                )
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
                nowPlayingInfoCenter.nowPlayingInfo = nil
                #if os(macOS)
                    nowPlayingInfoCenter.playbackState = .stopped
                #endif
                updateCommandAvailability()
                return
            }

            let requiresArtwork = publicationState.beginPublishing(trackID: track.id)
            let existingArtwork =
                requiresArtwork
                ? nil
                : nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork]
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
            nowPlayingInfoCenter.nowPlayingInfo = information
            #if os(iOS)
                nowPlayingSession.becomeActiveIfPossible(completion: nil)
            #else
                nowPlayingInfoCenter.playbackState = controller.isPlaying ? .playing : .paused
            #endif

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
                #if os(iOS)
                    self?.installArtwork(UIImage(cgImage: decodedImage), for: track.id)
                #else
                    let size = NSSize(width: decodedImage.width, height: decodedImage.height)
                    self?.installArtwork(NSImage(cgImage: decodedImage, size: size), for: track.id)
                #endif
            }
        }

        #if os(iOS)
            private func installArtwork(_ image: UIImage, for trackID: UUID) {
                guard controller.currentTrack?.id == trackID else { return }
                var information = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
                information[MPMediaItemPropertyArtwork] = Self.mediaItemArtwork(for: image)
                nowPlayingInfoCenter.nowPlayingInfo = information
            }

            nonisolated private static func mediaItemArtwork(for image: UIImage) -> MPMediaItemArtwork {
                MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        #else
            private func installArtwork(_ image: NSImage, for trackID: UUID) {
                guard controller.currentTrack?.id == trackID else { return }
                var information = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
                information[MPMediaItemPropertyArtwork] = Self.mediaItemArtwork(for: image)
                nowPlayingInfoCenter.nowPlayingInfo = information
            }

            nonisolated private static func mediaItemArtwork(for image: NSImage) -> MPMediaItemArtwork {
                MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        #endif

        private func updateCommandAvailability() {
            let commands = remoteCommandCenter
            commands.nextTrackCommand.isEnabled = controller.queue.canGoNext
            commands.previousTrackCommand.isEnabled = controller.queue.canGoPrevious
            commands.changePlaybackPositionCommand.isEnabled = controller.currentTrack != nil
        }
    }
#endif
