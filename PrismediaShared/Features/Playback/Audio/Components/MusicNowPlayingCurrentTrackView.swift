#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicNowPlayingCurrentTrackView: View {
        let track: MusicTrack
        let artworkNamespace: Namespace.ID
        let artworkIsSource: Bool
        let showsContent: Bool
        let hasHistory: Bool
        let onShowPlayer: () -> Void
        let onShowHistory: () -> Void
        let onNavigate: (EntityLink) -> Void
        let onAddToCollection: (() -> Void)?

        init(
            track: MusicTrack,
            artworkNamespace: Namespace.ID,
            artworkIsSource: Bool = true,
            showsContent: Bool,
            hasHistory: Bool,
            onShowPlayer: @escaping () -> Void,
            onShowHistory: @escaping () -> Void,
            onNavigate: @escaping (EntityLink) -> Void,
            onAddToCollection: (() -> Void)?
        ) {
            self.track = track
            self.artworkNamespace = artworkNamespace
            self.artworkIsSource = artworkIsSource
            self.showsContent = showsContent
            self.hasHistory = hasHistory
            self.onShowPlayer = onShowPlayer
            self.onShowHistory = onShowHistory
            self.onNavigate = onNavigate
            self.onAddToCollection = onAddToCollection
        }

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
                                        anchor: .center,
                                        isSource: artworkIsSource
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
                    MusicTrackActionsMenu(
                        track: track,
                        onNavigate: onNavigate,
                        onAddToCollection: onAddToCollection
                    )
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
                onNavigate: { _ in },
                onAddToCollection: {}
            )
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
