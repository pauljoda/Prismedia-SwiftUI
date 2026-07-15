#if os(iOS) || os(macOS)
    import SwiftUI

    struct ReaderAudiobookButton: View {
        let isPlaying: Bool
        let action: () -> Void

        var body: some View {
            Button(
                "Audiobook Now Playing",
                systemImage: isPlaying ? "headphones.circle.fill" : "headphones.circle",
                action: action
            )
            .accessibilityHint("Opens companion audiobook playback controls")
            .accessibilityIdentifier("epub-reader.audiobook-controls")
        }
    }

    #if DEBUG
        #Preview("Reader Audiobook Button") {
            ReaderAudiobookButton(isPlaying: true, action: {})
                .padding()
                .background(PrismediaBackdrop())
                .preferredColorScheme(.dark)
        }
    #endif
#endif
