#if os(iOS) || os(tvOS)
    import AVFoundation
    import AVKit
    import Foundation
    import MediaPlayer
    import UIKit

    @MainActor
    final class VideoNowPlayingCoordinator {
        private static let artworkMaximumPixelSize = 1_024

        private let service: any VideoPlaybackServicing
        private var controller: VideoPlaybackController?
        private var metadata: VideoNowPlayingMetadata?
        private var nowPlayingSession: MPNowPlayingSession?
        private var currentItemObservation: NSKeyValueObservation?
        private var playerStateObservation: NSKeyValueObservation?
        private var commandTargets: [(command: MPRemoteCommand, target: Any)] = []
        private var artworkTask: Task<Void, Never>?
        private var artworkData: Data?
        private var artworkImage: UIImage?

        init(service: any VideoPlaybackServicing) {
            self.service = service
        }

        var integration: VideoSystemPlaybackIntegration {
            VideoSystemPlaybackIntegration(
                activate: { [self] controller, metadata in
                    activate(controller, metadata: metadata)
                },
                deactivate: { [self] controller in
                    deactivate(controller)
                }
            )
        }

        private func activate(
            _ controller: VideoPlaybackController,
            metadata: VideoNowPlayingMetadata
        ) {
            let controllerChanged = self.controller !== controller
            if controllerChanged {
                tearDownSession()
                self.controller = controller
                let session = MPNowPlayingSession(players: [controller.player])
                session.automaticallyPublishesNowPlayingInfo = true
                nowPlayingSession = session
                registerCommands(in: session.remoteCommandCenter, controller: controller)
                currentItemObservation = controller.player.observe(
                    \.currentItem,
                    options: [.initial, .new]
                ) { [weak self] _, _ in
                    Task { @MainActor in self?.publishCurrentItem() }
                }
                playerStateObservation = controller.player.observe(
                    \.timeControlStatus,
                    options: [.initial, .new]
                ) { [weak self] player, _ in
                    guard player.timeControlStatus == .playing else { return }
                    Task { @MainActor in
                        _ = await self?.nowPlayingSession?.becomeActiveIfPossible()
                    }
                }
            }

            if self.metadata?.contentID != metadata.contentID
                || self.metadata?.artworkPath != metadata.artworkPath
            {
                artworkTask?.cancel()
                artworkTask = nil
                artworkData = nil
                artworkImage = nil
            }
            self.metadata = metadata
            publishCurrentItem()
            nowPlayingSession?.becomeActiveIfPossible(completion: nil)
        }

        private func deactivate(_ controller: VideoPlaybackController) {
            guard self.controller === controller else { return }
            tearDownSession()
        }

        private func publishCurrentItem() {
            guard let controller,
                let metadata,
                let currentItem = controller.player.currentItem
            else { return }

            currentItem.externalMetadata = Self.externalMetadata(
                for: metadata,
                artworkData: artworkData
            )
            currentItem.nowPlayingInfo = Self.nowPlayingInfo(
                for: metadata,
                duration: controller.duration,
                artworkImage: artworkImage
            )

            guard artworkData == nil, artworkImage == nil, artworkTask == nil,
                let path = metadata.artworkPath,
                let url = service.authenticatedMediaURL(for: path)
            else { return }
            let contentID = metadata.contentID
            artworkTask = Task { [weak self] in
                let pipeline = RemoteArtworkPipeline.shared
                do {
                    async let data = pipeline.data(for: url)
                    async let decodedImage = pipeline.image(
                        for: url,
                        maxPixelSize: Self.artworkMaximumPixelSize
                    )
                    let artwork = try await (data, decodedImage)
                    guard !Task.isCancelled else { return }
                    self?.installArtwork(
                        artwork.0,
                        image: UIImage(cgImage: artwork.1),
                        contentID: contentID
                    )
                } catch {
                    return
                }
            }
        }

        private func installArtwork(_ data: Data, image: UIImage, contentID: UUID) {
            artworkTask = nil
            guard metadata?.contentID == contentID else { return }
            artworkData = data
            artworkImage = image
            publishCurrentItem()
        }

        private func registerCommands(
            in commands: MPRemoteCommandCenter,
            controller: VideoPlaybackController
        ) {
            register(commands.playCommand) { [weak controller] _ in
                guard let controller else { return .noSuchContent }
                Task { @MainActor in controller.play() }
                return .success
            }
            register(commands.pauseCommand) { [weak controller] _ in
                guard let controller else { return .noSuchContent }
                Task { @MainActor in controller.pause() }
                return .success
            }
            register(commands.togglePlayPauseCommand) { [weak controller] _ in
                guard let controller else { return .noSuchContent }
                Task { @MainActor in controller.togglePlayback() }
                return .success
            }
            register(commands.changePlaybackPositionCommand) { [weak controller] event in
                guard let controller,
                    let event = event as? MPChangePlaybackPositionCommandEvent
                else { return .commandFailed }
                Task { @MainActor in controller.seek(to: event.positionTime) }
                return .success
            }
            commands.skipBackwardCommand.preferredIntervals = [10]
            register(commands.skipBackwardCommand) { [weak controller] _ in
                guard let controller else { return .noSuchContent }
                Task { @MainActor in controller.skip(by: -10) }
                return .success
            }
            commands.skipForwardCommand.preferredIntervals = [10]
            register(commands.skipForwardCommand) { [weak controller] _ in
                guard let controller else { return .noSuchContent }
                Task { @MainActor in controller.skip(by: 10) }
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

        private func tearDownSession() {
            artworkTask?.cancel()
            artworkTask = nil
            currentItemObservation = nil
            playerStateObservation = nil
            if let currentItem = controller?.player.currentItem {
                currentItem.externalMetadata = []
                currentItem.nowPlayingInfo = nil
            }
            for registration in commandTargets {
                registration.command.removeTarget(registration.target)
            }
            commandTargets = []
            nowPlayingSession = nil
            controller = nil
            metadata = nil
            artworkData = nil
            artworkImage = nil
        }

        private static func nowPlayingInfo(
            for metadata: VideoNowPlayingMetadata,
            duration: Double,
            artworkImage: UIImage?
        ) -> [String: Any] {
            var information: [String: Any] = [
                MPMediaItemPropertyTitle: metadata.title,
                MPNowPlayingInfoPropertyExternalContentIdentifier: metadata.contentID.uuidString.lowercased(),
                MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue,
            ]
            if let subtitle = metadata.subtitle {
                information[MPMediaItemPropertyArtist] = subtitle
            }
            if duration.isFinite, duration > 0 {
                information[MPMediaItemPropertyPlaybackDuration] = duration
            }
            if let artworkImage {
                information[MPMediaItemPropertyArtwork] = mediaItemArtwork(for: artworkImage)
            }
            return information
        }

        private static func externalMetadata(
            for metadata: VideoNowPlayingMetadata,
            artworkData: Data?
        ) -> [AVMetadataItem] {
            var items = [metadataItem(identifier: .commonIdentifierTitle, value: metadata.title as NSString)]
            if let subtitle = metadata.subtitle {
                items.append(
                    metadataItem(
                        identifier: .iTunesMetadataTrackSubTitle,
                        value: subtitle as NSString
                    )
                )
            }
            if let artworkData {
                items.append(
                    metadataItem(
                        identifier: .commonIdentifierArtwork,
                        value: artworkData as NSData
                    )
                )
            }
            return items
        }

        private static func metadataItem(
            identifier: AVMetadataIdentifier,
            value: NSCopying & NSObjectProtocol
        ) -> AVMetadataItem {
            let item = AVMutableMetadataItem()
            item.identifier = identifier
            item.value = value
            item.extendedLanguageTag = "und"
            return item
        }

        /// MediaPlayer can invoke this request handler away from MainActor.
        nonisolated private static func mediaItemArtwork(for image: UIImage) -> MPMediaItemArtwork {
            MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
    }
#endif
