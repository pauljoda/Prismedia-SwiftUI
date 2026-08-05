#if os(iOS) || os(macOS)
    import AVFoundation
    import SwiftUI

    struct MusicNowPlayingTransportView: View {
        @Environment(MusicPlayerController.self) private var controller
        #if os(macOS)
            @State private var volume = 1.0
        #endif

        let track: MusicTrack
        let engine: AVPlayerAudioPlaybackEngine
        let selectedTint: Color
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

                auxiliaryControl
            }
        }

        @ViewBuilder
        private var transport: some View {
            transportButtons
                .buttonStyle(.plain)
        }

        private var transportButtons: some View {
            HStack(spacing: 54) {
                previousButton
                playButton
                nextButton
            }
            .font(.system(size: 27, weight: .semibold))
            .padding(.top, PrismediaSpacing.large)
        }

        private var previousButton: some View {
            Button("Previous", systemImage: "backward.fill", action: controller.skipToPrevious)
                .labelStyle(.iconOnly)
                .foregroundStyle(selectedTint.opacity(0.78))
                .disabled(!controller.queue.canGoPrevious)
        }

        private var playButton: some View {
            Button(
                controller.isPlaying ? "Pause" : "Play",
                systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                action: togglePlayback
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(selectedTint)
            .frame(width: 64, height: 64)
            .contentTransition(.identity)
            .animation(nil, value: controller.isPlaying)
        }

        private var nextButton: some View {
            Button("Next", systemImage: "forward.fill", action: controller.skipToNext)
                .labelStyle(.iconOnly)
                .foregroundStyle(selectedTint.opacity(0.78))
                .disabled(!controller.queue.canGoNext)
        }

        @ViewBuilder
        private var auxiliaryControl: some View {
            Group {
                if controller.context?.isAudiobook == true {
                    MusicPlaybackRateControl(controller: controller)
                } else {
                    volumeControl
                }
            }
            .padding(.horizontal, PrismediaSpacing.section)
            .padding(.top, PrismediaSpacing.extraLarge)
            .padding(.bottom, PrismediaSpacing.medium)
        }

        @ViewBuilder
        private var volumeControl: some View {
            #if os(iOS)
                SystemVolumeSlider()
                    .frame(height: 28)
            #else
                HStack(spacing: PrismediaSpacing.small) {
                    Image(systemName: "speaker.fill")
                    Slider(value: $volume, in: 0...1)
                        .tint(selectedTint)
                        .accessibilityLabel("Volume")
                    Image(systemName: "speaker.wave.3.fill")
                }
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
                .onAppear { volume = Double(engine.player.volume) }
                .onChange(of: volume) { _, value in
                    engine.player.volume = Float(min(max(value, 0), 1))
                }
            #endif
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
                selectedTint: PrismediaColor.accent,
                scrubPosition: $scrubPosition,
                isScrubbing: $isScrubbing
            )
            .environment(controller)
            .padding(.vertical)
            .background(PrismediaBackdrop())
        }
    #endif
#endif
