#if os(macOS)
    import SwiftUI

    struct MacMusicMiniPlayerView: View {
        @Environment(\.musicMiniPlayerVisibility) private var visibility
        @Environment(MusicPlayerController.self) private var controller

        let showNowPlaying: () -> Void

        var body: some View {
            if let track = controller.currentTrack {
                HStack(spacing: PrismediaSpacing.medium) {
                    Button(action: showNowPlaying) {
                        HStack(spacing: PrismediaSpacing.medium) {
                            RemotePosterImage(
                                path: track.artworkPath,
                                fallbackSeed: track.album ?? track.title,
                                systemImage: "music.note"
                            )
                            .frame(width: 38, height: 38)
                            .clipShape(.rect(cornerRadius: PrismediaRadius.badge))

                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                                Text(track.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(MusicPresentation.artist(track.artist))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(minWidth: 180, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show Now Playing for \(track.title)")

                    Spacer(minLength: 8)

                    Button("Previous Track", systemImage: "backward.fill", action: controller.skipToPrevious)
                        .labelStyle(.iconOnly)
                        .disabled(!controller.queue.canGoPrevious)

                    Button(
                        controller.isPlaying ? "Pause" : "Play",
                        systemImage: controller.isPlaying ? "pause.fill" : "play.fill",
                        action: togglePlayback
                    )
                    .labelStyle(.iconOnly)
                    .contentTransition(.identity)

                    Button("Next Track", systemImage: "forward.fill", action: controller.skipToNext)
                        .labelStyle(.iconOnly)
                        .disabled(!controller.queue.canGoNext)

                    Spacer(minLength: 8)

                    Button("Show Queue", systemImage: "list.bullet", action: showNowPlaying)
                        .labelStyle(.iconOnly)
                }
                .controlSize(.large)
                .padding(.horizontal, PrismediaSpacing.large)
                .padding(.vertical, PrismediaSpacing.small)
                .background(.bar)
                .overlay(alignment: .top) { Divider() }
                .contextMenu {
                    Button("Hide Player", systemImage: "xmark") {
                        visibility?.hideByUser()
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("music.mini-player")
            }
        }

        private func togglePlayback() {
            withoutMusicControlAnimation {
                controller.isPlaying ? controller.pause() : controller.resume()
            }
        }
    }

    #if DEBUG
        #Preview("Mac Music Mini Player") {
            @Previewable @State var controller = MusicPreviewData.controller()
            MacMusicMiniPlayerView(showNowPlaying: {})
                .environment(controller)
                .frame(width: 620)
        }
    #endif
#endif
