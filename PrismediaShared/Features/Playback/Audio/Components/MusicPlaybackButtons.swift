#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicPlaybackButtons: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let loadingMode: MusicQueueStartMode?
        let isDisabled: Bool
        let action: (MusicQueueStartMode) -> Void

        var body: some View {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: PrismediaSpacing.medium) {
                        playButton
                        shuffleButton
                    }
                } else {
                    HStack(spacing: PrismediaSpacing.medium) {
                        playButton
                        shuffleButton
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(loadingMode != nil || isDisabled)
        }

        private var playButton: some View {
            PrismediaButton(
                "Play",
                systemImage: "play.fill",
                variant: .prominent,
                form: .fill,
                isLoading: loadingMode == .ordered
            ) {
                action(.ordered)
            }
            .accessibilityIdentifier("music.library.play")
        }

        private var shuffleButton: some View {
            PrismediaButton(
                "Shuffle",
                systemImage: "shuffle",
                form: .fill,
                isLoading: loadingMode == .shuffled
            ) {
                action(.shuffled)
            }
            .accessibilityIdentifier("music.library.shuffle")
        }
    }

    #if DEBUG
        #Preview("Music Playback Buttons · Dark") {
            PreviewShell {
                MusicPlaybackButtons(loadingMode: nil, isDisabled: false) { _ in }
                    .padding()
                    .background(PrismediaBackdrop())
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Music Playback Buttons · Accessibility") {
            PreviewShell {
                MusicPlaybackButtons(loadingMode: .shuffled, isDisabled: false) { _ in }
                    .padding()
                    .background(PrismediaBackdrop())
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
