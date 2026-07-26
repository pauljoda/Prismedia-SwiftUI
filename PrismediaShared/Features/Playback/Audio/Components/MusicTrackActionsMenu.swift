#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicTrackActionsMenu: View {
        let track: MusicTrack
        let onNavigate: (EntityLink) -> Void
        let onAddToCollection: (() -> Void)?
        let onShowNowPlaying: (() -> Void)?
        let onHidePlayer: (() -> Void)?

        init(
            track: MusicTrack,
            onNavigate: @escaping (EntityLink) -> Void,
            onAddToCollection: (() -> Void)? = nil,
            onShowNowPlaying: (() -> Void)? = nil,
            onHidePlayer: (() -> Void)? = nil
        ) {
            self.track = track
            self.onNavigate = onNavigate
            self.onAddToCollection = onAddToCollection
            self.onShowNowPlaying = onShowNowPlaying
            self.onHidePlayer = onHidePlayer
        }

        var body: some View {
            Menu {
                if let onShowNowPlaying {
                    Button("Show Now Playing", systemImage: "music.note.list", action: onShowNowPlaying)
                }

                if track.albumNavigationLink != nil || track.artistNavigationLink != nil {
                    Menu("Go To", systemImage: "arrow.up.right") {
                        if let albumLink = track.albumNavigationLink {
                            Button("Album", systemImage: "square.stack") {
                                onNavigate(albumLink)
                            }
                        }

                        if let artistLink = track.artistNavigationLink {
                            Button("Artist", systemImage: "music.mic") {
                                onNavigate(artistLink)
                            }
                        }
                    }
                }

                if let onAddToCollection {
                    Button("Add to Collection", systemImage: "rectangle.stack.badge.plus") {
                        onAddToCollection()
                    }
                }

                if let onHidePlayer {
                    Divider()
                    Button("Hide Player", systemImage: "xmark", action: onHidePlayer)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .frame(
                        width: PrismediaLayout.minimumHitTarget,
                        height: PrismediaLayout.minimumHitTarget
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More actions for \(track.title)")
            .accessibilityHint("Shows collection and library navigation actions")
            .accessibilityIdentifier("music.track-actions")
        }
    }

    #if DEBUG
        #Preview("Music Track Actions") {
            MusicTrackActionsMenu(
                track: MusicPreviewData.tracks[0],
                onNavigate: { _ in },
                onAddToCollection: {},
                onShowNowPlaying: {},
                onHidePlayer: {}
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    #endif
#endif
