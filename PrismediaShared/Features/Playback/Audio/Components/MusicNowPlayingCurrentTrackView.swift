#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingCurrentTrackView: View {
        let track: MusicTrack
        let artworkNamespace: Namespace.ID
        let showsContent: Bool
        let onShowPlayer: () -> Void
        let onAddToCollection: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Text("Currently Playing")
                    .font(.title3.bold())
                    .opacity(showsContent ? 1 : 0)
                    .accessibilityIdentifier("music.queue.current")

                HStack(spacing: PrismediaSpacing.medium) {
                    Color.clear
                        .frame(width: 78, height: 78)
                        .overlay {
                            if showsContent {
                                MusicNowPlayingArtwork(track: track)
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
                        .onTapGesture(perform: onShowPlayer)
                        .accessibilityAddTraits(.isButton)
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
                    Menu {
                        Button("Add to Collection", systemImage: "folder.badge.plus") {
                            onAddToCollection()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
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
                onShowPlayer: {},
                onAddToCollection: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
