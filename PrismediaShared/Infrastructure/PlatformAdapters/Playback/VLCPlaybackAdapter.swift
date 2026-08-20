#if canImport(VLCKit)
    import Foundation
    @preconcurrency import VLCKit

    @MainActor
    final class VLCPlaybackAdapter: NSObject, VLCMediaPlayerDelegate {
        private weak var controller: VideoPlaybackController?
        private var mediaPlayer: VLCMediaPlayer?
        private var request: VideoCompatibilityPlaybackRequest?
        private var openingState = VideoCompatibilityPlaybackOpeningState()
        private var stateFilter = VideoCompatibilityPlaybackStateFilter()
        private var audioSelectionState = VideoCompatibilityAudioSelectionState()
        private var stopWasRequested = false
        private var profile5BufferingIsActive = false
        private var pendingResumeSeekSeconds: Double?
        private var pendingVideoOutputTargetSeconds: Double?

        init(controller: VideoPlaybackController) {
            self.controller = controller
        }

        func install(_ request: VideoCompatibilityPlaybackRequest, drawable: AnyObject) {
            tearDownPlayer()
            self.request = request
            stateFilter = VideoCompatibilityPlaybackStateFilter()
            audioSelectionState.prepare(
                initialStreamIndex: request.audioStreams.first(where: \.isSelected)?.index
            )

            guard let media = VLCMedia(url: request.url) else {
                controller?.compatibilityPlaybackDidFail(
                    "The compatibility player could not open this video."
                )
                return
            }
            media.addOption(":no-spu")
            media.addOption(
                ":network-caching=\(VLCNetworkCachingSettings.milliseconds(for: request.networkCachingSeconds, dolbyVisionProfile: request.dolbyVisionProfile))"
            )
            // VLC's standard HTTP access forwards http-token, but its adaptive
            // HLS access needs our VLCKit patch to apply it to child playlists
            // and segments. Only authenticated playback plans add this option.
            if let httpBearerToken = request.httpBearerToken {
                media.addOption(":http-token=\(httpBearerToken)")
            }
            VLCCompatibilityPlaybackOptions.containerOptions(
                trustMatroskaCues: request.trustMatroskaCues
            ).forEach(media.addOption)
            VLCCompatibilityPlaybackOptions.mediaOptions(
                dolbyVisionProfile: request.dolbyVisionProfile,
                platform: playbackPlatform,
                hardwareDecoderAvailable: hardwareDecoderAvailable
            ).forEach(media.addOption)
            // Never resume through VLC's ":start-time" option: on HTTP sources it positions the
            // input by demuxing linearly from the head of the file to the target instead of using
            // the container's seek index, which downloads gigabytes before the first frame. A
            // deferred `player.time` seek issued once playback opens takes the indexed path — the
            // same one interactive scrubbing uses.
            pendingResumeSeekSeconds = request.resumeTime > 0 ? request.resumeTime : nil
            pendingVideoOutputTargetSeconds = request.resumeTime
            let playerOptions = VLCCompatibilityPlaybackOptions.playerOptions(
                dolbyVisionProfile: request.dolbyVisionProfile,
                platform: playbackPlatform
            )
            let player = VLCMediaPlayer(options: playerOptions)
            player.drawable = drawable
            player.delegate = self
            player.media = media
            player.rate = request.playbackRate
            #if os(tvOS)
                // Apple TV cannot bitstream every compatibility codec (notably
                // TrueHD). Decode through the multichannel audio session so the
                // system can deliver PCM to HDMI or spatialize it for AirPods.
                player.audio?.passthrough = false
            #endif
            mediaPlayer = player
            stopWasRequested = false
            profile5BufferingIsActive = false

            controller?.attachCompatibilityPlayback(commands(for: player))
            controller?.videoSurfaceDidAttach(isReadyForDisplay: false)
            openingState.prepare(
                hasRequestedPlayback: controller?.hasRequestedPlayback == true
            )
            player.play()
        }

        func update(
            _ request: VideoCompatibilityPlaybackRequest,
            controller: VideoPlaybackController,
            drawable: AnyObject
        ) {
            if self.controller !== controller {
                let previousController = self.controller
                tearDownPlayer()
                previousController?.detachCompatibilityPlayback()
                previousController?.videoSurfaceDidDetach()
                self.controller = controller
                install(request, drawable: drawable)
                return
            }
            guard self.request != request else { return }
            install(request, drawable: drawable)
        }

        func tearDown() {
            tearDownPlayer()
            controller?.detachCompatibilityPlayback()
            controller?.videoSurfaceDidDetach()
            request = nil
        }

        nonisolated func mediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
            Task { @MainActor [weak self] in
                self?.handleMediaPlayerStateChanged(state)
            }
        }

        private func handleMediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
            guard let player = mediaPlayer else { return }
            disableNativeSubtitleRendering(on: player)
            switch state {
            case .playing:
                player.rate = request?.playbackRate ?? 1
                applyInitialAudioSelection(to: player)
                applyPendingResumeSeekIfNeeded(on: player)
                publishVideoOutputReadiness(on: player)
                if openingState.shouldPauseAfterOpening() {
                    player.pause()
                    publishState(isPlaying: false, isWaiting: false)
                    return
                }
                publishState(
                    isPlaying: true,
                    isWaiting: request?.dolbyVisionProfile == 5
                        && profile5BufferingIsActive
                )
            case .opening:
                if request?.dolbyVisionProfile == 5 {
                    profile5BufferingIsActive = true
                }
                publishState(isPlaying: false, isWaiting: true)
            case .paused:
                profile5BufferingIsActive = false
                publishState(isPlaying: false, isWaiting: false)
            case .stopped:
                profile5BufferingIsActive = false
                publishState(isPlaying: false, isWaiting: false)
                if !stopWasRequested {
                    controller?.compatibilityPlaybackDidFinish()
                }
            case .error:
                profile5BufferingIsActive = false
                controller?.compatibilityPlaybackDidFail(
                    "The compatibility player could not decode this video."
                )
            case .stopping, .nothingSpecial:
                profile5BufferingIsActive = false
                publishState(isPlaying: false, isWaiting: false)
            @unknown default:
                profile5BufferingIsActive = false
                publishState(isPlaying: false, isWaiting: false)
            }
        }

        nonisolated func mediaPlayerBufferingChanged(_ progress: Float) {
            Task { @MainActor [weak self] in
                self?.handleMediaPlayerBufferingChanged(progress)
            }
        }

        private func handleMediaPlayerBufferingChanged(_ progress: Float) {
            guard let player = mediaPlayer else { return }
            let completionThreshold: Float = request?.dolbyVisionProfile == 5 ? 0.99 : 1
            let isWaiting = VideoCompatibilityPlaybackStateFilter.isWaiting(
                progress: progress,
                completionThreshold: completionThreshold
            )
            if request?.dolbyVisionProfile == 5 {
                profile5BufferingIsActive = isWaiting
            }
            publishVideoOutputReadiness(on: player)
            publishState(isPlaying: player.isPlaying, isWaiting: isWaiting)
        }

        nonisolated func mediaPlayerTimeChanged(_ notification: Notification) {
            Task { @MainActor [weak self] in
                guard let self, let player = self.mediaPlayer else { return }
                self.publishVideoOutputReadiness(on: player)
                self.publishState(
                    isPlaying: player.isPlaying,
                    isWaiting: self.request?.dolbyVisionProfile == 5
                        && self.profile5BufferingIsActive
                )
            }
        }

        private func commands(for player: VLCMediaPlayer) -> VideoCompatibilityPlaybackCommands {
            VideoCompatibilityPlaybackCommands(
                play: { [weak self, weak player] rate in
                    self?.openingState.requestPlayback()
                    self?.stopWasRequested = false
                    player?.rate = rate
                    player?.play()
                },
                pause: { [weak player] in player?.pause() },
                seek: { [weak self, weak player] seconds in
                    guard let self, let player else { return }
                    self.pendingVideoOutputTargetSeconds = seconds
                    self.controller?.videoSurfaceReadinessChanged(false)
                    stateFilter.beginSeek(to: seconds, at: ProcessInfo.processInfo.systemUptime)
                    player.time = VLCTime(int: Int32(seconds * 1_000))
                },
                stop: { [weak self, weak player] in
                    self?.stopWasRequested = true
                    player?.stop()
                },
                setRate: { [weak player] rate in player?.rate = rate },
                selectAudioStream: { [weak self, weak player] streamIndex in
                    guard let self, let player else { return }
                    audioSelectionState.explicitSelectionWasRequested()
                    selectAudioStream(streamIndex, on: player)
                }
            )
        }

        private func publishState(isPlaying: Bool, isWaiting: Bool) {
            guard let player = mediaPlayer else { return }
            // Delegate ordering is not guaranteed: a time or buffering callback can observe a
            // playing engine before the state callback runs. Applying the deferred resume here
            // keeps any first playing publication at the resume target instead of zero.
            if player.isPlaying {
                applyPendingResumeSeekIfNeeded(on: player)
            }
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
            guard let streamIndex = audioSelectionState.takeInitialStreamIndex() else { return }
            selectAudioStream(streamIndex, on: player)
        }

        /// Applies the deferred resume position exactly once, the first time the player reaches
        /// its playing state. The seek-protection filter keeps published state (and therefore
        /// session reports) at the resume target while VLC completes the jump, so a transient
        /// zero position never reaches the UI or the server.
        private func applyPendingResumeSeekIfNeeded(on player: VLCMediaPlayer) {
            guard let target = pendingResumeSeekSeconds else { return }
            pendingResumeSeekSeconds = nil
            stateFilter.beginSeek(to: target, at: ProcessInfo.processInfo.systemUptime)
            player.time = VLCTime(int: Int32(target * 1_000))
        }

        /// A playing state means VLC's clock and audio pipeline have started; it
        /// does not mean a decoded video frame exists. `hasVideoOut` becomes true
        /// only once the video output is established. Keep the player visibly
        /// loading until that output is at the requested start/seek position.
        private func publishVideoOutputReadiness(on player: VLCMediaPlayer) {
            guard player.hasVideoOut else { return }
            let size = player.videoSize
            guard size.width > 0, size.height > 0 else { return }
            if let target = pendingVideoOutputTargetSeconds {
                let current = Double(player.time.intValue) / 1_000
                guard abs(current - target) <= 3 else { return }
            }
            pendingVideoOutputTargetSeconds = nil
            controller?.videoSurfaceReadinessChanged(true)
        }

        private func disableNativeSubtitleRendering(on player: VLCMediaPlayer) {
            player.deselectAllTextTracks()
        }

        private func selectAudioStream(_ streamIndex: Int, on player: VLCMediaPlayer) {
            guard let request,
                let position = request.audioStreams.firstIndex(where: { $0.index == streamIndex })
            else { return }
            guard player.audioTracks.indices.contains(position) else { return }
            player.selectTrack(at: position, type: .audio)
        }

        private var playbackPlatform: VLCCompatibilityPlaybackPlatform {
            #if os(iOS)
                .iOS
            #elseif os(tvOS)
                .tvOS
            #else
                .macOS
            #endif
        }

        private var hardwareDecoderAvailable: Bool {
            #if targetEnvironment(simulator)
                false
            #else
                true
            #endif
        }

        private func tearDownPlayer() {
            mediaPlayer?.delegate = nil
            mediaPlayer?.stop()
            mediaPlayer?.drawable = nil
            mediaPlayer = nil
            openingState = VideoCompatibilityPlaybackOpeningState()
            stateFilter = VideoCompatibilityPlaybackStateFilter()
            audioSelectionState = VideoCompatibilityAudioSelectionState()
            stopWasRequested = false
            profile5BufferingIsActive = false
            pendingResumeSeekSeconds = nil
            pendingVideoOutputTargetSeconds = nil
        }
    }
#endif
