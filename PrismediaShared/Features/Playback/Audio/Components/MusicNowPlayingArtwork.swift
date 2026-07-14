#if os(iOS)
    import SwiftUI

    struct MusicNowPlayingArtwork: View {
        let track: MusicTrack

        var body: some View {
            RemotePosterImage(
                path: track.artworkPath,
                fallbackSeed: track.album ?? track.title,
                systemImage: "music.note",
                contentMode: .fit,
                imageCornerRadius: PrismediaRadius.control
            )
            .aspectRatio(1, contentMode: .fit)
        }
    }

    #if DEBUG
        #Preview("Now Playing Artwork") {
            MusicNowPlayingArtwork(track: MusicPreviewData.tracks[0])
                .frame(width: 280, height: 280)
                .environment(PrismediaPreviewData.model(signedIn: true))
                .padding()
                .background(PrismediaBackdrop())
        }
    #endif
#endif
