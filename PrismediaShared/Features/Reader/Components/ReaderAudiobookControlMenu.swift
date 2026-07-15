import SwiftUI

struct ReaderAudiobookControlMenu: View {
    let trackTitle: String
    let isPlaying: Bool
    let playbackRate: Float
    let onTogglePlayback: () -> Void
    let onSetPlaybackRate: (Float) -> Void

    var body: some View {
        Menu {
            Text(trackTitle)

            Button(
                isPlaying ? "Pause Audiobook" : "Play Audiobook",
                systemImage: isPlaying ? "pause.fill" : "play.fill",
                action: onTogglePlayback
            )

            Menu("Playback Speed", systemImage: "speedometer") {
                ForEach(MusicPlaybackRateOption.standard) { option in
                    Button {
                        onSetPlaybackRate(option.rate)
                    } label: {
                        if playbackRate == option.rate {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
            }
        } label: {
            Label(
                "Audiobook",
                systemImage: isPlaying ? "headphones.circle.fill" : "headphones.circle"
            )
        }
        .accessibilityHint("Controls companion audiobook playback and speed")
        .accessibilityIdentifier("epub-reader.audiobook-controls")
    }
}

#if DEBUG
    #Preview("Reader Audiobook Controls") {
        ReaderAudiobookControlMenu(
            trackTitle: "Chapter 7: The Long Way Home",
            isPlaying: true,
            playbackRate: 1.25,
            onTogglePlayback: {},
            onSetPlaybackRate: { _ in }
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
