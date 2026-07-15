import SwiftUI

struct ReaderAudiobookControlMenu: View {
    @Binding var isPresented: Bool

    let trackTitle: String
    let isPlaying: Bool
    let playbackRate: Float
    let onTogglePlayback: () -> Void
    let onSetPlaybackRate: (Float) -> Void

    var body: some View {
        #if os(tvOS)
            Menu {
                Button(
                    isPlaying ? "Pause Audiobook" : "Play Audiobook",
                    systemImage: isPlaying ? "pause.fill" : "play.fill",
                    action: onTogglePlayback
                )

                playbackRateMenu
            } label: {
                Label(
                    "Audiobook",
                    systemImage: isPlaying ? "headphones.circle.fill" : "headphones.circle"
                )
            }
            .accessibilityHint("Controls companion audiobook playback and speed")
            .accessibilityIdentifier("epub-reader.audiobook-controls")
        #else
            popoverButton
        #endif
    }

    #if !os(tvOS)
        private var popoverButton: some View {
            Button("Audiobook", systemImage: isPlaying ? "headphones.circle.fill" : "headphones.circle") {
                isPresented = true
            }
            .popover(isPresented: $isPresented, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    Text(trackTitle)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .lineLimit(2)

                    Button(
                        isPlaying ? "Pause Audiobook" : "Play Audiobook",
                        systemImage: isPlaying ? "pause.fill" : "play.fill",
                        action: onTogglePlayback
                    )
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)

                    playbackRateMenu
                }
                .padding(PrismediaSpacing.large)
                .frame(minWidth: 280, idealWidth: 320)
                .presentationCompactAdaptation(.popover)
            }
            .accessibilityHint("Controls companion audiobook playback and speed")
            .accessibilityIdentifier("epub-reader.audiobook-controls")
        }
    #endif

    private var playbackRateMenu: some View {
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
    }
}

#if DEBUG
    #Preview("Reader Audiobook Controls") {
        @Previewable @State var isPresented = true

        ReaderAudiobookControlMenu(
            isPresented: $isPresented,
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
