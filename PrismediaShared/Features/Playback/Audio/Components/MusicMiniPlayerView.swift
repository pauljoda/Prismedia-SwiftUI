#if os(iOS)
    import SwiftUI

    struct MusicMiniPlayerView: View {
        @Environment(\.tabViewBottomAccessoryPlacement) private var placement
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(MusicPlayerController.self) private var controller
        let showNowPlaying: () -> Void

        var body: some View {
            if let track = controller.currentTrack {
                HStack(spacing: placement == .inline ? 8 : 12) {
                    Button(action: showNowPlaying) {
                        HStack(spacing: placement == .inline ? 8 : 12) {
                            MusicNowPlayingArtwork(
                                track: track,
                                cornerRadius: PrismediaRadius.badge
                            )
                            .frame(width: artworkContentSize, height: artworkContentSize)
                            .padding(artworkInset)
                            .frame(width: artworkSize, height: artworkSize)

                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                                Text(track.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if placement != .inline {
                                    Text(MusicPresentation.artist(track.artist))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 4)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Now Playing, \(track.title)")

                    Button(action: togglePlayback) {
                        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body.weight(.bold))
                            .frame(width: 32, height: 32)
                            .contentTransition(.identity)
                            .animation(nil, value: controller.isPlaying)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(controller.isPlaying ? "Pause" : "Play")

                    if placement != .inline {
                        Button(action: controller.skipToNext) {
                            Image(systemName: "forward.fill")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .disabled(!controller.queue.canGoNext)
                        .accessibilityLabel("Next Track")
                    }
                }
                .padding(.horizontal, placement == .inline ? 6 : 10)
                .padding(.vertical, placement == .inline ? 3 : 6)
                .contextMenu {
                    Button("Hide Player", systemImage: "xmark") {
                        visibility?.hideByUser()
                    }
                }
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private var artworkSize: CGFloat { placement == .inline ? 32 : 46 }
        private var artworkInset: CGFloat { placement == .inline ? 2 : 4 }
        private var artworkContentSize: CGFloat { artworkSize - (artworkInset * 2) }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("Music Mini Player") {
            @Previewable @State var controller = MusicPreviewData.controller()
            MusicMiniPlayerView(showNowPlaying: {})
                .environment(controller)
                .padding()
        }
    #endif
#endif
