#if !os(tvOS)
    import SwiftUI

    /// The playback chrome as a panel of its own for the flat half of a half-closed
    /// iPhone Duo, below the video in the raised half. Unlike the overlay chrome it
    /// stays on screen, and its controls are large tiles meant for a hand resting
    /// on the table.
    struct VideoTabletopControlPanel: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let controller: VideoPlaybackController
        let title: String
        var trickplayPlaylistPath: String?
        var trickplayFrameLoader: (any TrickplayFrameLoading)?
        let onExitFullscreen: () -> Void
        var onDismiss: (() -> Void)?

        var body: some View {
            VStack(spacing: PrismediaSpacing.medium) {
                header
                transport
                timeline
                options
            }
            .padding(.horizontal, PrismediaSpacing.extraLarge)
            .padding(.vertical, PrismediaSpacing.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PrismediaColor.groupedContentBackground)
            .foregroundStyle(PrismediaColor.onMedia)
            .buttonBorderShape(.roundedRectangle(radius: PrismediaRadius.control))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("video-player.tabletop-panel")
        }

        private var header: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                if let onDismiss {
                    Button(action: onDismiss) {
                        tileLabel("Exit Full Screen", systemImage: "xmark")
                    }
                    .buttonStyle(.glass)
                    .frame(width: PrismediaLayout.minimumHitTarget * 1.5)
                }

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(artworkPrimaryAccent)
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                #if os(iOS)
                    if controller.renderer == .native {
                        Button(action: controller.startPictureInPicture) {
                            tileLabel("Start Picture in Picture", systemImage: "pip.enter")
                        }
                        .buttonStyle(.glass)
                        .frame(width: PrismediaLayout.minimumHitTarget * 1.5)
                    }
                #endif
            }
            .frame(height: PrismediaLayout.minimumHitTarget)
        }

        private var transport: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button {
                    controller.skip(by: -10)
                } label: {
                    tileLabel("Back 10 Seconds", systemImage: "gobackward.10", font: .title2.weight(.semibold))
                }
                .buttonStyle(.glass)

                // The panel's one prominent action, styled like PrismediaButton's.
                Button(action: controller.togglePlayback) {
                    tileLabel(
                        isPlaying ? "Pause" : "Play",
                        systemImage: isPlaying ? "pause.fill" : "play.fill",
                        font: .largeTitle.weight(.bold)
                    )
                }
                .buttonStyle(.glassProminent)
                .tint(artworkPrimaryAccent)
                .foregroundStyle(PrismediaColor.onAccent)
                .accessibilityIdentifier(isPlaying ? "video-detail.pause" : "video-detail.play")

                Button {
                    controller.skip(by: 10)
                } label: {
                    tileLabel("Forward 10 Seconds", systemImage: "goforward.10", font: .title2.weight(.semibold))
                }
                .buttonStyle(.glass)
            }
            .frame(maxHeight: .infinity)
        }

        private var timeline: some View {
            VStack(spacing: PrismediaSpacing.extraSmall) {
                VideoPlaybackTimeline(
                    controller: controller,
                    trickplayPlaylistPath: trickplayPlaylistPath,
                    trickplayFrameLoader: trickplayFrameLoader
                )
                HStack {
                    Text(VideoPlaybackPresentation.clockTime(controller.currentTime))
                    Spacer()
                    Text(
                        "−\(VideoPlaybackPresentation.clockTime(max(0, controller.duration - controller.currentTime)))"
                    )
                }
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(PrismediaColor.onMedia.opacity(0.72))
            }
        }

        private var options: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Menu {
                    ForEach(VideoPlaybackSettings.availableRates, id: \.self) { rate in
                        choice(
                            VideoPlaybackSettings.label(for: rate),
                            selected: controller.playbackRate == rate
                        ) {
                            controller.setPlaybackRate(rate)
                        }
                    }
                } label: {
                    tileLabel("Playback Speed", systemImage: "speedometer")
                }

                Menu {
                    ForEach(controller.subtitleChoices) { subtitle in
                        choice(subtitle.title, selected: controller.selectedSubtitleChoiceID == subtitle.id) {
                            Task { await controller.selectSubtitle(id: subtitle.id) }
                        }
                    }
                } label: {
                    tileLabel("Subtitles", systemImage: "captions.bubble")
                }

                Menu {
                    if controller.audioChoices.isEmpty {
                        choice("Default", selected: true) {}
                            .disabled(true)
                    } else {
                        ForEach(controller.audioChoices) { audio in
                            choice(audio.title, selected: controller.selectedAudioChoiceID == audio.id) {
                                Task { await controller.selectAudio(id: audio.id) }
                            }
                        }
                    }
                } label: {
                    tileLabel("Audio", systemImage: "waveform")
                }

                Menu {
                    ForEach(VideoScalingMode.allCases) { mode in
                        choice(mode.label, selected: controller.videoScalingMode == mode) {
                            controller.setVideoScalingMode(mode)
                        }
                    }
                } label: {
                    tileLabel("Video Size", systemImage: "rectangle.arrowtriangle.2.outward")
                }

                Button(action: onExitFullscreen) {
                    tileLabel("Exit Full Screen", systemImage: "arrow.down.right.and.arrow.up.left")
                }
            }
            .menuStyle(.button)
            .buttonStyle(.glass)
            .frame(height: PrismediaLayout.minimumHitTarget)
        }

        private var isPlaying: Bool {
            controller.isPlaying || controller.isWaiting
        }

        private func tileLabel(_ title: String, systemImage: String, font: Font = .headline) -> some View {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(font)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
        }

        private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                if selected {
                    Label(title, systemImage: "checkmark")
                } else {
                    Text(title)
                }
            }
        }
    }
#endif
