#if os(macOS)
    import SwiftUI

    struct MacMusicNowPlayingView: View {
        @Environment(MusicPlayerController.self) private var controller
        @State private var scrubPosition = 0.0
        @State private var isScrubbing = false
        @State private var artworkPalette: ArtworkPalette?

        let engine: AVPlayerAudioPlaybackEngine

        var body: some View {
            Group {
                if let track = controller.currentTrack {
                    ArtworkPaletteSurface(
                        artworkPath: track.artworkPath,
                        fallbackSeed: track.album ?? track.title,
                        systemImage: "music.note",
                        palette: $artworkPalette
                    ) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                                artwork(track)
                                metadata(track)
                                timeline(track)
                                transport
                                queueModes
                                queue
                            }
                            .padding(PrismediaSpacing.extraLarge)
                        }
                    }
                } else {
                    ContentUnavailableView("Nothing Playing", systemImage: "music.note")
                }
            }
            .navigationTitle("Now Playing")
            .onChange(of: engine.elapsedTime) { _, elapsedTime in
                if !isScrubbing { scrubPosition = elapsedTime }
            }
        }

        private func artwork(_ track: MusicTrack) -> some View {
            EntityThumbnailArtworkFrame(aspectRatio: 1) {
                RemotePosterImage(
                    path: track.artworkPath,
                    fallbackSeed: track.album ?? track.title,
                    systemImage: "music.note"
                )
            }
            .frame(maxWidth: 280)
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
            .frame(maxWidth: .infinity)
        }

        private func metadata(_ track: MusicTrack) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(track.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                Text([track.album, track.artist].compactMap { $0 }.joined(separator: " — "))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .accessibilityElement(children: .combine)
        }

        private func timeline(_ track: MusicTrack) -> some View {
            MusicPlaybackTimeline(
                position: $scrubPosition,
                duration: max(engine.duration, track.duration ?? 0, 1),
                onEditingChanged: { scrubDidChange($0) }
            )
        }

        private var transport: some View {
            HStack(spacing: PrismediaSpacing.extraLarge) {
                Button("Previous Track", systemImage: "backward.fill", action: controller.skipToPrevious)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoPrevious)

                Button(
                    controller.isPlaying ? "Pause" : "Play",
                    systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                    action: togglePlayback
                )
                .labelStyle(.iconOnly)
                .font(.title2)
                .contentTransition(.identity)

                Button("Next Track", systemImage: "forward.fill", action: controller.skipToNext)
                    .labelStyle(.iconOnly)
                    .disabled(!controller.queue.canGoNext)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }

        private var queueModes: some View {
            HStack {
                Toggle(
                    "Shuffle",
                    systemImage: "shuffle",
                    isOn: Binding(
                        get: { controller.queue.isShuffled },
                        set: { controller.setShuffleEnabled($0) }
                    )
                )
                .toggleStyle(.button)
                .disabled(controller.context?.isAudiobook == true)
                .accessibilityHint(
                    controller.context?.isAudiobook == true
                        ? "Audiobook parts play in order"
                        : "Changes queue order"
                )

                Button(repeatLabel, systemImage: repeatSystemImage) {
                    controller.cycleRepeatMode()
                }
            }
            .buttonStyle(.bordered)
        }

        private var queue: some View {
            let upNextTracks = controller.queue.upNextTracks
            return LazyVStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(controller.context?.isAudiobook == true ? "Up Next Parts" : "Up Next")
                    .font(.headline)

                if upNextTracks.isEmpty {
                    Text("No more tracks in the queue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upNextTracks) { track in
                        HStack(spacing: PrismediaSpacing.small) {
                            RemotePosterImage(
                                path: track.artworkPath,
                                fallbackSeed: track.album ?? track.title,
                                systemImage: "music.note"
                            )
                            .frame(width: 32, height: 32)
                            .clipShape(.rect(cornerRadius: PrismediaRadius.badge))
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                                Text(track.title).lineLimit(1)
                                Text(MusicPresentation.artist(track.artist))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        Divider()
                    }
                }
            }
        }

        private var repeatSystemImage: String {
            controller.queue.repeatMode == .one ? "repeat.1" : "repeat"
        }

        private var repeatLabel: String {
            switch controller.queue.repeatMode {
            case .off: "Repeat Off"
            case .all: "Repeat All"
            case .one: "Repeat One"
            }
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
        #Preview("Mac Now Playing") {
            @Previewable @State var controller = MusicPreviewData.controller()
            @Previewable @State var engine = AVPlayerAudioPlaybackEngine()
            MacMusicNowPlayingView(engine: engine)
                .environment(controller)
                .frame(width: 360, height: 720)
        }
    #endif
#endif
