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

                volumeControl
            }
        }

        @ViewBuilder
        private var transport: some View {
            #if os(iOS)
                transportButtons
                    .buttonStyle(.plain)
            #else
                transportButtons
            #endif
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

        @ViewBuilder
        private var previousButton: some View {
            let button = Button("Previous", systemImage: "backward.fill", action: controller.skipToPrevious)
                .labelStyle(.iconOnly)
                .disabled(!controller.queue.canGoPrevious)

            #if os(macOS)
                button
                    .buttonStyle(.glass)
                    .foregroundStyle(selectedTint.opacity(0.78))
            #else
                button
            #endif
        }

        @ViewBuilder
        private var playButton: some View {
            let button = Button(
                controller.isPlaying ? "Pause" : "Play",
                systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                action: togglePlayback
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 38, weight: .bold))
            .frame(width: 64, height: 64)
            .contentTransition(.identity)
            .animation(nil, value: controller.isPlaying)

            #if os(macOS)
                button
                    .buttonStyle(.glassProminent)
                    .tint(selectedTint)
            #else
                button
            #endif
        }

        @ViewBuilder
        private var nextButton: some View {
            let button = Button("Next", systemImage: "forward.fill", action: controller.skipToNext)
                .labelStyle(.iconOnly)
                .disabled(!controller.queue.canGoNext)

            #if os(macOS)
                button
                    .buttonStyle(.glass)
                    .foregroundStyle(selectedTint.opacity(0.78))
            #else
                button
            #endif
        }

        @ViewBuilder
        private var volumeControl: some View {
            #if os(iOS)
                SystemVolumeSlider()
                    .frame(height: 28)
                    .padding(.horizontal, PrismediaSpacing.section)
                    .padding(.top, PrismediaSpacing.extraLarge)
                    .padding(.bottom, PrismediaSpacing.medium)
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
                .padding(.horizontal, PrismediaSpacing.section)
                .padding(.top, PrismediaSpacing.extraLarge)
                .padding(.bottom, PrismediaSpacing.medium)
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
