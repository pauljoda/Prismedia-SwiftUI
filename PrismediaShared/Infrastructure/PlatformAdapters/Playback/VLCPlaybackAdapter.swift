#if canImport(TVVLCKit) || canImport(MobileVLCKit) || canImport(VLCKit)
    import Foundation
    #if canImport(TVVLCKit)
        @preconcurrency import TVVLCKit
    #elseif canImport(MobileVLCKit)
        @preconcurrency import MobileVLCKit
    #elseif canImport(VLCKit)
        @preconcurrency import VLCKit
    #endif

    @MainActor
    final class VLCPlaybackAdapter: NSObject, VLCMediaPlayerDelegate {
        private weak var controller: VideoPlaybackController?
        private var mediaPlayer: VLCMediaPlayer?
        private var request: VideoCompatibilityPlaybackRequest?
        private var pausesAfterOpening = false
        private var stateFilter = VideoCompatibilityPlaybackStateFilter()

        init(controller: VideoPlaybackController) {
            self.controller = controller
        }

        func install(_ request: VideoCompatibilityPlaybackRequest, drawable: AnyObject) {
            tearDownPlayer()
            self.request = request
            stateFilter = VideoCompatibilityPlaybackStateFilter()

            let media = VLCMedia(url: request.url)
            #if !targetEnvironment(simulator)
                // Prefer VLC's native Apple decoder, then keep VideoToolbox active
                // if the avcodec path is selected for the source codec. Simulators
                // need VLC's software fallback because they have no device decoder.
                media.addOption(":codec=videotoolbox,any")
                media.addOption(":videotoolbox-hw-decoder-only=1")
                media.addOption(":avcodec-hw=videotoolbox")
            #endif
            if request.resumeTime > 0 {
                media.addOption(":start-time=\(request.resumeTime)")
            }
            let player = VLCMediaPlayer()
            player.drawable = drawable
            player.delegate = self
            player.media = media
            player.rate = request.playbackRate
            mediaPlayer = player

            controller?.attachCompatibilityPlayback(commands(for: player))
            controller?.videoSurfaceDidAttach(isReadyForDisplay: false)
            pausesAfterOpening = controller?.hasRequestedPlayback == false
            player.play()
        }

        func update(_ request: VideoCompatibilityPlaybackRequest, drawable: AnyObject) {
            guard self.request != request else { return }
            install(request, drawable: drawable)
        }

        func tearDown() {
            tearDownPlayer()
            controller?.detachCompatibilityPlayback()
            controller?.videoSurfaceDidDetach()
            request = nil
        }

        func mediaPlayerStateChanged(_ notification: Notification) {
            guard let player = mediaPlayer else { return }
            switch player.state {
            case .playing:
                player.rate = request?.playbackRate ?? 1
                applyInitialAudioSelection(to: player)
                controller?.videoSurfaceReadinessChanged(true)
                if pausesAfterOpening {
                    pausesAfterOpening = false
                    player.pause()
                    publishState(isPlaying: false, isWaiting: false)
                    return
                }
                publishState(isPlaying: true, isWaiting: false)
            case .opening, .buffering, .esAdded:
                publishState(isPlaying: false, isWaiting: true)
            case .paused:
                publishState(isPlaying: false, isWaiting: false)
            case .ended:
                publishState(isPlaying: false, isWaiting: false)
                controller?.compatibilityPlaybackDidFinish()
            case .error:
                controller?.compatibilityPlaybackDidFail(
                    "The compatibility player could not decode this video."
                )
            case .stopped:
                publishState(isPlaying: false, isWaiting: false)
            @unknown default:
                publishState(isPlaying: false, isWaiting: false)
            }
        }

        func mediaPlayerTimeChanged(_ notification: Notification) {
            guard let player = mediaPlayer else { return }
            publishState(isPlaying: player.isPlaying, isWaiting: false)
        }

        private func commands(for player: VLCMediaPlayer) -> VideoCompatibilityPlaybackCommands {
            VideoCompatibilityPlaybackCommands(
                play: { [weak player] rate in
                    player?.rate = rate
                    player?.play()
                },
                pause: { [weak player] in player?.pause() },
                seek: { [weak self, weak player] seconds in
                    guard let self, let player else { return }
                    stateFilter.beginSeek(to: seconds, at: ProcessInfo.processInfo.systemUptime)
                    player.time = VLCTime(int: Int32(seconds * 1_000))
                },
                stop: { [weak player] in player?.stop() },
                setRate: { [weak player] rate in player?.rate = rate },
                selectAudioStream: { [weak self, weak player] streamIndex in
                    guard let self, let player else { return }
                    selectAudioStream(streamIndex, on: player)
                }
            )
        }

        private func publishState(isPlaying: Bool, isWaiting: Bool) {
            guard let player = mediaPlayer else { return }
            let candidate = VideoCompatibilityPlaybackState(
                currentTime: Double(player.time.intValue) / 1_000,
                duration: Double(player.media?.length.intValue ?? 0) / 1_000,
                isPlaying: isPlaying,
                isWaiting: isWaiting
            )
            guard
                let state = stateFilter.stateToPublish(
                    candidate,
                    at: ProcessInfo.processInfo.systemUptime
                )
            else { return }
            controller?.compatibilityPlaybackDidUpdate(
                currentTime: state.currentTime,
                duration: state.duration,
                isPlaying: state.isPlaying,
                isWaiting: state.isWaiting
            )
        }

        private func applyInitialAudioSelection(to player: VLCMediaPlayer) {
            guard let streamIndex = request?.audioStreams.first(where: \.isSelected)?.index else { return }
            selectAudioStream(streamIndex, on: player)
        }

        private func selectAudioStream(_ streamIndex: Int, on player: VLCMediaPlayer) {
            guard let request,
                let position = request.audioStreams.firstIndex(where: { $0.index == streamIndex }),
                let trackIndexes = player.audioTrackIndexes as? [NSNumber],
                trackIndexes.indices.contains(position + 1)
            else { return }
            player.currentAudioTrackIndex = trackIndexes[position + 1].int32Value
        }

        private func tearDownPlayer() {
            mediaPlayer?.delegate = nil
            mediaPlayer?.stop()
            mediaPlayer?.drawable = nil
            mediaPlayer = nil
            pausesAfterOpening = false
            stateFilter = VideoCompatibilityPlaybackStateFilter()
        }
    }
#endif
