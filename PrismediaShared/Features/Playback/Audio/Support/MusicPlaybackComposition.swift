#if os(iOS) || os(macOS)
    import Foundation
    import Observation

    @Observable
    @MainActor
    final class MusicPlaybackComposition {
        let engine: AVPlayerAudioPlaybackEngine
        let controller: MusicPlayerController
        var artworkPalette: ArtworkPalette?

        private let serviceRelay: MusicPlaybackServiceRelay
        private var artworkTrackID: UUID?

        init() {
            let engine = AVPlayerAudioPlaybackEngine()
            let serviceRelay = MusicPlaybackServiceRelay()
            let stateStore: any MusicPlaybackStatePersisting
            #if DEBUG
                stateStore =
                    CommandLine.arguments.contains("-prismedia-ui-testing")
                    ? EphemeralMusicPlaybackStateStore()
                    : UserDefaultsMusicPlaybackStateStore()
            #else
                stateStore = UserDefaultsMusicPlaybackStateStore()
            #endif
            self.engine = engine
            self.serviceRelay = serviceRelay
            controller = MusicPlayerController(
                engine: engine,
                service: serviceRelay,
                stateStore: stateStore
            )
            controller.restoreIfNeeded()
        }

        func prepareArtworkPalette(
            for track: MusicTrack?,
            artworkURL: URL?,
            loader: any ArtworkPaletteLoading
        ) async {
            artworkTrackID = track?.id
            guard let track, let artworkURL else {
                artworkPalette = nil
                return
            }

            let resolved = await loader.palette(for: artworkURL)
            guard !Task.isCancelled, artworkTrackID == track.id else { return }
            artworkPalette = resolved
        }

        func connect(to service: any MusicPlaybackServicing) {
            serviceRelay.connect(to: service)
            controller.playbackServiceDidConnect()
        }

        func disconnect() {
            controller.playbackServiceDidDisconnect()
            serviceRelay.disconnect()
        }

        func clearSession() {
            controller.discardPlaybackState()
            serviceRelay.disconnect()
            artworkPalette = nil
            artworkTrackID = nil
        }

        func artworkURL(for path: String?) -> URL? {
            serviceRelay.artworkURL(for: path)
        }

        var playbackService: any MusicPlaybackServicing {
            serviceRelay
        }
    }
#endif
