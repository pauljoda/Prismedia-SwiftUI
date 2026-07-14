#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicPlaybackButtons: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let isBusy: Bool
        let isDisabled: Bool
        let action: (Bool) -> Void

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
            .disabled(isBusy || isDisabled)
        }

        private var playButton: some View {
            PrismediaButton(
                "Play",
                systemImage: "play.fill",
                variant: .prominent,
                form: .fill
            ) {
                action(false)
            }
            .accessibilityIdentifier("music.library.play")
        }

        private var shuffleButton: some View {
            PrismediaButton("Shuffle", systemImage: "shuffle", form: .fill) {
                action(true)
            }
            .accessibilityIdentifier("music.library.shuffle")
        }
    }

    #if DEBUG
        #Preview("Music Playback Buttons · Dark") {
            PreviewShell {
                MusicPlaybackButtons(isBusy: false, isDisabled: false) { _ in }
                    .padding()
                    .background(PrismediaBackdrop())
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Music Playback Buttons · Accessibility") {
            PreviewShell {
                MusicPlaybackButtons(isBusy: false, isDisabled: false) { _ in }
                    .padding()
                    .background(PrismediaBackdrop())
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
