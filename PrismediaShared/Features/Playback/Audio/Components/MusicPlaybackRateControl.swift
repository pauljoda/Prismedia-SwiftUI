#if os(iOS) || os(macOS)
    import SwiftUI

    /// Presents the supported audiobook reading-rate range without owning a second playback value.
    struct MusicPlaybackRateControl: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let controller: MusicPlayerController

        var body: some View {
            HStack(spacing: PrismediaSpacing.small) {
                Image(systemName: "speedometer")
                    .accessibilityHidden(true)

                Slider(value: playbackRate, in: 0.5...2, step: 0.25) {
                    Text("Reading Speed")
                }
                .tint(artworkPrimaryAccent)
                .accessibilityValue(rateLabel)

                Text(rateLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .frame(minWidth: 34, alignment: .trailing)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(PrismediaColor.textSecondary)
            .frame(minHeight: 28)
            .accessibilityIdentifier("music.playback-rate")
        }

        private var playbackRate: Binding<Double> {
            Binding(
                get: { Double(controller.playbackRate) },
                set: { controller.setPlaybackRate(Float($0)) }
            )
        }

        private var rateLabel: String {
            MusicPlaybackRateOption(rate: controller.playbackRate).label
        }
    }

    #if DEBUG
        #Preview("Audiobook Playback Rate") {
            MusicPlaybackRateControl(controller: MusicPreviewData.audiobookController())
                .padding()
                .background(PrismediaBackdrop())
        }
    #endif
#endif
