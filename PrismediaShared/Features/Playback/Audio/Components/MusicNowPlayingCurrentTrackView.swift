#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingCurrentTrackView: View {
        let track: MusicTrack
        let artworkNamespace: Namespace.ID
        let showsContent: Bool
        let hasHistory: Bool
        let onShowPlayer: () -> Void
        let onShowHistory: () -> Void
        let onAddToCollection: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack {
                    Text("Currently Playing")
                        .font(.title3.bold())
                        .accessibilityIdentifier("music.queue.current")

                    Spacer()

                    if hasHistory {
                        Button("History", action: onShowHistory)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("music.queue.show-history")
                    }
                }
                .opacity(showsContent ? 1 : 0)
                .accessibilityHidden(!showsContent)

                HStack(spacing: PrismediaSpacing.medium) {
                    Button(action: onShowPlayer) {
                        Color.clear
                            .frame(width: 78, height: 78)
                            .overlay {
                                if showsContent {
                                    MusicNowPlayingArtwork(
                                        track: track,
                                        cornerRadius: PrismediaRadius.badge
                                    )
                                    .matchedGeometryEffect(
                                        id: "music.now-playing.artwork.\(track.id.uuidString)",
                                        in: artworkNamespace,
                                        properties: .frame,
                                        anchor: .center
                                    )
                                    .zIndex(1)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!showsContent)
                    .accessibilityHidden(!showsContent)
                    .accessibilityLabel("Show Now Playing")
                    .accessibilityHint("Shows the full Now Playing view")

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(MusicPresentation.artist(track.artist))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .opacity(showsContent ? 1 : 0)
                    Spacer(minLength: 0)
                    Button("Add to Collection", systemImage: "ellipsis", action: onAddToCollection)
                        .labelStyle(.iconOnly)
                        .opacity(showsContent ? 1 : 0)
                }
            }
        }
    }

    #if DEBUG
        #Preview("Queue Current Track") {
            @Previewable @Namespace var artworkNamespace
            MusicNowPlayingCurrentTrackView(
                track: MusicPreviewData.tracks[0],
                artworkNamespace: artworkNamespace,
                showsContent: true,
                hasHistory: true,
                onShowPlayer: {},
                onShowHistory: {},
                onAddToCollection: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
