#if os(macOS)
    import SwiftUI

    struct MacMusicCompactWaveformProgressView: View {
        let waveform: MusicWaveform
        let progress: Double
        let accent: Color
        let secondaryAccent: Color

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    waveformTrack(
                        width: geometry.size.width,
                        primary: PrismediaColor.textMuted.opacity(0.34),
                        secondary: PrismediaColor.textMuted.opacity(0.28)
                    )

                    waveformTrack(
                        width: geometry.size.width,
                        primary: accent.opacity(0.72),
                        secondary: secondaryAccent.opacity(0.58)
                    )
                    .frame(width: geometry.size.width * normalizedProgress, alignment: .leading)
                    .clipped()
                }
            }
            .accessibilityHidden(true)
        }

        private func waveformTrack(
            width: CGFloat,
            primary: Color,
            secondary: Color
        ) -> some View {
            MacMusicWaveformTrack(
                waveform: waveform,
                stripWidth: width,
                accent: primary,
                secondaryAccent: secondary
            )
            .frame(width: width)
        }

        private var normalizedProgress: CGFloat {
            CGFloat(min(max(progress.isFinite ? progress : 0, 0), 1))
        }
    }

    #if DEBUG
        #Preview("Mac Compact Waveform Progress") {
            PreviewShell(signedIn: true) {
                MacMusicCompactWaveformProgressView(
                    waveform: MusicWaveformPreviewLoader.waveform,
                    progress: 0.42,
                    accent: PrismediaColor.materialSpectrumGreen,
                    secondaryAccent: PrismediaColor.materialSpectrumBlue
                )
                .frame(width: 420, height: 8)
                .padding()
            }
        }
    #endif
#endif
