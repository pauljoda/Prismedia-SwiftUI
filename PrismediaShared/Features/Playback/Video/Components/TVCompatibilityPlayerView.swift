#if os(tvOS)
    import SwiftUI

    struct TVCompatibilityPlayerView: View {
        let controller: VideoPlaybackController
        let request: VideoCompatibilityPlaybackRequest
        let onRequestDismiss: () -> Void

        @State private var controlsVisible = true

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.black
                TVVLCPlayerController(request: request, controller: controller)
                    .ignoresSafeArea()

                if controlsVisible {
                    controls
                        .transition(.opacity)
                }
            }
            .background(Color.black)
            .focusable()
            .focusEffectDisabled()
            .onTapGesture { controlsVisible.toggle() }
            .onPlayPauseCommand {
                controlsVisible = true
                controller.togglePlayback()
            }
            .onMoveCommand { direction in
                controlsVisible = true
                switch direction {
                case .left: controller.skip(by: -10)
                case .right: controller.skip(by: 10)
                default: break
                }
            }
            .onExitCommand(perform: onRequestDismiss)
            .task(id: controller.isPlaying) {
                guard controller.isPlaying else { return }
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled, controller.isPlaying else { return }
                controlsVisible = false
            }
            .animation(.easeOut(duration: 0.18), value: controlsVisible)
            .accessibilityIdentifier("video-player.compatibility-surface")
        }

        private var controls: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                HStack(spacing: PrismediaSpacing.large) {
                    controlButton("gobackward.10", label: "Back 10 Seconds") {
                        controller.skip(by: -10)
                    }
                    controlButton(
                        controller.isPlaying || controller.isWaiting ? "pause.fill" : "play.fill",
                        label: controller.isPlaying || controller.isWaiting ? "Pause" : "Play",
                        prominent: true,
                        action: controller.togglePlayback
                    )
                    controlButton("goforward.10", label: "Forward 10 Seconds") {
                        controller.skip(by: 10)
                    }
                    controlButton("xmark", label: "Exit Player", action: onRequestDismiss)
                }

                ProgressView(
                    value: min(controller.currentTime, max(controller.duration, 0)),
                    total: max(controller.duration, 1)
                )
                .tint(PrismediaColor.onMedia)

                HStack {
                    Text(VideoPlaybackPresentation.clockTime(controller.currentTime))
                    Spacer()
                    Text(VideoPlaybackPresentation.clockTime(controller.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 24)
            .background(Color.black.opacity(0.72))
        }

        private func controlButton(
            _ systemImage: String,
            label: String,
            prominent: Bool = false,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: prominent ? 31 : 25, weight: .semibold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .frame(width: prominent ? 76 : 64, height: prominent ? 76 : 64)
                    .contentShape(Circle())
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            .accessibilityLabel(label)
        }
    }

    #if DEBUG
        #Preview("TV Compatibility Player") {
            TVCompatibilityPlayerView(
                controller: VideoPlaybackController(
                    videoID: UUID(uuidString: "A57450E8-AC6C-4930-9C1E-B3995675D702")!,
                    service: VideoPlaybackPreviewService()
                ),
                request: VideoCompatibilityPlaybackRequest(
                    url: URL(string: "https://example.com/video.mkv")!,
                    resumeTime: 42,
                    playbackRate: 1,
                    audioStreams: []
                ),
                onRequestDismiss: {}
            )
        }
    #endif
#endif
