#if canImport(TVVLCKit) || canImport(MobileVLCKit) || canImport(VLCKit)
    import Foundation
    #if os(tvOS) && canImport(VLCKit)
        @preconcurrency import VLCKit
    #elseif canImport(TVVLCKit)
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
        private var openingState = VideoCompatibilityPlaybackOpeningState()
        private var stateFilter = VideoCompatibilityPlaybackStateFilter()
        private var audioSelectionState = VideoCompatibilityAudioSelectionState()
        private var stopWasRequested = false
        private var profile5BufferingIsActive = false
        private var pendingResumeSeekSeconds: Double?

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

            #if os(tvOS) && canImport(VLCKit)
                guard let media = VLCMedia(url: request.url) else {
                    controller?.compatibilityPlaybackDidFail(
                        "The compatibility player could not open this video."
                    )
                    return
                }
            #else
                let media = VLCMedia(url: request.url)
            #endif
            media.addOption(":no-spu")
            media.addOption(
                ":network-caching=\(VLCNetworkCachingSettings.milliseconds(for: request.networkCachingSeconds, dolbyVisionProfile: request.dolbyVisionProfile))"
            )
            #if !targetEnvironment(simulator)
                // Prefer VLC's native Apple decoder. Simulators need VLC's
                // software fallback because they have no device decoder.
                #if os(tvOS) && canImport(VLCKit)
                    if request.dolbyVisionProfile == 5 {
                        // Profile 5 has no HDR10-compatible base layer. Route its
                        // RPU metadata from VideoToolbox into libplacebo so VLC can
                        // reshape hardware-decoded frames before display.
                        media.addOption(":codec=videotoolbox,any")
                        media.addOption(":videotoolbox-hw-decoder-only=1")
                        media.addOption(":videotoolbox-dovi-profile5")
                        // Apple TV's GLES texture cache cannot expose x420
                        // (10-bit bi-planar) as normalized 16-bit textures.
                        // Ask VideoToolbox for the Profile 5 full-range NV12
                        // presentation surface while retaining hardware HEVC.
                        media.addOption(":videotoolbox-cvpx-chroma=420f")
                    } else {
                        media.addOption(":codec=videotoolbox,any")
                        media.addOption(":videotoolbox-hw-decoder-only=1")
                    }
                #else
                    media.addOption(":codec=videotoolbox,any")
                    media.addOption(":videotoolbox-hw-decoder-only=1")
                    media.addOption(":avcodec-hw=videotoolbox")
                #endif
            #endif
            // Never resume through VLC's ":start-time" option: on HTTP sources it positions the
            // input by demuxing linearly from the head of the file to the target instead of using
            // the container's seek index, which downloads gigabytes before the first frame. A
            // deferred `player.time` seek issued once playback opens takes the indexed path — the
            // same one interactive scrubbing uses.
            pendingResumeSeekSeconds = request.resumeTime > 0 ? request.resumeTime : nil
            #if os(tvOS) && canImport(VLCKit)
                let player =
                    request.dolbyVisionProfile == 5
                    ? VLCMediaPlayer(options: ["--vout=gles2", "--gl-dovi-profile5"])
                    : VLCMediaPlayer()
            #else
                let player = VLCMediaPlayer()
            #endif
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

        #if os(tvOS) && canImport(VLCKit)
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
                    controller?.videoSurfaceReadinessChanged(true)
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
                publishState(isPlaying: player.isPlaying, isWaiting: isWaiting)
            }
        #else
            func mediaPlayerStateChanged(_ notification: Notification) {
                guard let player = mediaPlayer else { return }
                disableNativeSubtitleRendering(on: player)
                switch player.state {
                case .playing:
                    player.rate = request?.playbackRate ?? 1
                    applyInitialAudioSelection(to: player)
                    applyPendingResumeSeekIfNeeded(on: player)
                    controller?.videoSurfaceReadinessChanged(true)
                    if openingState.shouldPauseAfterOpening() {
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
        #endif

        #if os(tvOS) && canImport(VLCKit)
            nonisolated func mediaPlayerTimeChanged(_ notification: Notification) {
                Task { @MainActor [weak self] in
                    guard let self, let player = self.mediaPlayer else { return }
                    self.publishState(
                        isPlaying: player.isPlaying,
                        isWaiting: self.request?.dolbyVisionProfile == 5
                            && self.profile5BufferingIsActive
                    )
                }
            }
        #else
            func mediaPlayerTimeChanged(_ notification: Notification) {
                guard let player = mediaPlayer else { return }
                publishState(isPlaying: player.isPlaying, isWaiting: false)
            }
        #endif

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

        private func disableNativeSubtitleRendering(on player: VLCMediaPlayer) {
            #if os(tvOS) && canImport(VLCKit)
                player.deselectAllTextTracks()
            #else
                guard player.currentVideoSubTitleIndex != -1 else { return }
                player.currentVideoSubTitleIndex = -1
            #endif
        }

        private func selectAudioStream(_ streamIndex: Int, on player: VLCMediaPlayer) {
            guard let request,
                let position = request.audioStreams.firstIndex(where: { $0.index == streamIndex })
            else { return }
            #if os(tvOS) && canImport(VLCKit)
                guard player.audioTracks.indices.contains(position) else { return }
                player.selectTrack(at: position, type: .audio)
            #else
                guard
                    let trackIndexes = player.audioTrackIndexes as? [NSNumber],
                    trackIndexes.indices.contains(position + 1)
                else { return }
                player.currentAudioTrackIndex = trackIndexes[position + 1].int32Value
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
        }
    }
#endif
