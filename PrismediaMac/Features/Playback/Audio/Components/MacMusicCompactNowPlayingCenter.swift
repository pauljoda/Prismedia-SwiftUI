#if os(macOS)
    import AVFoundation
    import CoreMedia
    import SwiftUI

    struct MacMusicCompactNowPlayingCenter: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var positionAnchor = MacMusicPlaybackPositionAnchor()
        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
        @State private var isHovering = false

        let track: MusicTrack
        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let waveform: MusicWaveform?
        let accent: Color
        let secondaryAccent: Color
        let showNowPlaying: () -> Void

        var body: some View {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !engine.isPlaybackAdvancing)) { timeline in
                ZStack {
                    metadata(position: displayedPosition(at: timeline.date))
                        .opacity(isHovering ? 0 : 1)
                        .allowsHitTesting(!isHovering)

                    timelineControl(position: displayedPosition(at: timeline.date))
                        .opacity(isHovering ? 1 : 0)
                        .allowsHitTesting(isHovering)
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovering)
            }
            .frame(minWidth: 240, idealHeight: 46, maxHeight: 46)
            .contentShape(.rect)
            .onHover { isHovering = $0 }
            .onAppear(perform: synchronizePositionAnchor)
            .onChange(of: engine.elapsedTime) { _, value in
                guard !isScrubbing else { return }
                positionAnchor.synchronize(to: value)
                scrubPosition = value
            }
            .onChange(of: controller.isPlaying) { _, _ in synchronizePositionAnchor() }
            .onChange(of: engine.isPlaybackAdvancing) { _, _ in synchronizePositionAnchor() }
            .onChange(of: controller.playbackRate) { _, _ in synchronizePositionAnchor() }
            .onChange(of: track.id) { _, _ in synchronizePositionAnchor() }
        }

        private func metadata(position: Double) -> some View {
            Button(action: showNowPlaying) {
                HStack(spacing: PrismediaSpacing.small) {
                    MusicNowPlayingArtwork(
                        track: track,
                        cornerRadius: PrismediaRadius.badge
                    )
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(track.title)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Text(MusicPresentation.artist(track.artist))
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .lineLimit(1)

                        if let waveform {
                            MacMusicCompactWaveformProgressView(
                                waveform: waveform,
                                progress: position / duration,
                                accent: accent,
                                secondaryAccent: secondaryAccent
                            )
                            .frame(height: 4)
                        } else {
                            Capsule()
                                .fill(PrismediaColor.textMuted.opacity(0.22))
                                .frame(height: 3)
                                .overlay(alignment: .leading) {
                                    GeometryReader { geometry in
                                        Capsule()
                                            .fill(accent.opacity(0.55))
                                            .frame(width: geometry.size.width * progress(position))
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .accessibilityLabel("Show Now Playing for \(track.title)")
        }

        private func timelineControl(position: Double) -> some View {
            MusicPlaybackTimeline(
                position: Binding(
                    get: { isScrubbing ? scrubPosition : position },
                    set: { scrubPosition = $0 }
                ),
                duration: duration,
                onEditingChanged: scrubDidChange
            )
            .controlSize(.small)
            .environment(\.artworkPrimaryAccent, accent)
        }

        private var duration: Double {
            max(engine.duration, track.duration ?? 0, 1)
        }

        private func progress(_ position: Double) -> CGFloat {
            CGFloat(min(max(position / duration, 0), 1))
        }

        private func displayedPosition(at date: Date) -> Double {
            isScrubbing
                ? scrubPosition
                : positionAnchor.position(
                    at: date,
                    isPlaying: engine.isPlaybackAdvancing,
                    playbackRate: controller.playbackRate,
                    duration: duration
                )
        }

        private func synchronizePositionAnchor() {
            let currentTime = engine.player.currentTime().seconds
            let resolvedTime = currentTime.isFinite ? currentTime : engine.elapsedTime
            positionAnchor.synchronize(to: resolvedTime)
            if !isScrubbing { scrubPosition = resolvedTime }
        }

        private func scrubDidChange(_ editing: Bool) {
            if editing {
                scrubPosition = positionAnchor.position(
                    at: .now,
                    isPlaying: engine.isPlaybackAdvancing,
                    playbackRate: controller.playbackRate,
                    duration: duration
                )
                isScrubbing = true
            } else {
                isScrubbing = false
                positionAnchor.synchronize(to: scrubPosition)
                controller.seek(to: scrubPosition)
            }
        }
    }

    #if DEBUG
        #Preview("Mac Compact Now Playing Center") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()

            PreviewShell(signedIn: true) {
                MacMusicCompactNowPlayingCenter(
                    track: MusicPreviewData.tracks[0],
                    controller: controller,
                    engine: engine,
                    waveform: MusicWaveformPreviewLoader.waveform,
                    accent: PrismediaColor.materialSpectrumGreen,
                    secondaryAccent: PrismediaColor.materialSpectrumBlue,
                    showNowPlaying: {}
                )
                .frame(width: 420)
                .padding()
            }
        }
    #endif
#endif
