#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingTransportView: View {
        @Environment(MusicPlayerController.self) private var controller

        let track: MusicTrack
        let engine: AVPlayerAudioPlaybackEngine
        @Binding var scrubPosition: Double
        @Binding var isScrubbing: Bool

        var body: some View {
            VStack(spacing: 0) {
                MusicPlaybackTimeline(
                    position: $scrubPosition,
                    duration: max(engine.duration, track.duration ?? 0, 1),
                    onEditingChanged: scrubDidChange
                )
                .padding(.horizontal, PrismediaSpacing.section)

                transport

                SystemVolumeSlider()
                    .frame(height: 28)
                    .padding(.horizontal, PrismediaSpacing.section)
                    .padding(.top, PrismediaSpacing.extraLarge)
                    .padding(.bottom, PrismediaSpacing.medium)
            }
        }

        private var transport: some View {
            HStack(spacing: 54) {
                Button("Previous", systemImage: "backward.fill", action: controller.skipToPrevious)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoPrevious)

                Button(
                    controller.isPlaying ? "Pause" : "Play",
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    action: togglePlayback
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 38, weight: .bold))
                .frame(width: 64, height: 64)
                .contentTransition(.identity)
                .animation(nil, value: controller.isPlaying)

                Button("Next", systemImage: "forward.fill", action: controller.skipToNext)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoNext)
            }
            .font(.system(size: 27, weight: .semibold))
            .buttonStyle(.plain)
            .padding(.top, PrismediaSpacing.large)
        }

        private func scrubDidChange(_ editing: Bool) {
            isScrubbing = editing
            if !editing { controller.seek(to: scrubPosition) }
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("Now Playing Transport") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            @Previewable @State var scrubPosition = 42.0
            @Previewable @State var isScrubbing = false
            MusicNowPlayingTransportView(
                track: MusicPreviewData.tracks[0],
                engine: engine,
                scrubPosition: $scrubPosition,
                isScrubbing: $isScrubbing
            )
            .environment(controller)
            .padding(.vertical)
            .background(PrismediaBackdrop())
        }
    #endif
#endif
