#if !os(tvOS)
    import SwiftUI

    struct MusicPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Binding var position: Double
        let duration: Double
        let onEditingChanged: (Bool) -> Void

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraSmall) {
                Slider(
                    value: Binding(
                        get: { min(position, duration) },
                        set: { position = $0 }
                    ),
                    in: 0...duration,
                    onEditingChanged: onEditingChanged
                )
                .tint(artworkPrimaryAccent)
                .accessibilityLabel("Playback Position")
                .accessibilityValue(
                    "\(MusicPresentation.clockTime(position)) of \(MusicPresentation.clockTime(duration))"
                )

                HStack {
                    Text(MusicPresentation.clockTime(position))
                    Spacer()
                    Text("−\(MusicPresentation.clockTime(max(0, duration - position)))")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textSecondary)
            }
        }
    }

    #if DEBUG
        #Preview("Music Playback Timeline · Fallback") {
            @Previewable @State var position = 78.0
            MusicPlaybackTimeline(
                position: $position,
                duration: 240,
                onEditingChanged: { _ in }
            )
            .padding()
            .background(PrismediaColor.background)
        }

        #Preview("Music Playback Timeline · Artwork Accent") {
            @Previewable @State var position = 78.0
            MusicPlaybackTimeline(
                position: $position,
                duration: 240,
                onEditingChanged: { _ in }
            )
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumMagenta)
            .padding()
            .background(PrismediaColor.background)
        }
    #endif
#endif
