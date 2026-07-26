#if os(macOS)
    import SwiftUI

    struct MacMusicWaveformTrack: View {
        let waveform: MusicWaveform
        let stripWidth: CGFloat
        let accent: Color
        let secondaryAccent: Color

        var body: some View {
            Canvas { context, size in
                guard waveform.pairCount > 0, stripWidth > 0 else { return }
                let centerY = size.height / 2
                let sampleWidth = stripWidth / CGFloat(waveform.pairCount)
                let maximumAmplitude = waveform.maximumAmplitude

                for index in 0..<waveform.pairCount {
                    let minimum = waveform.samples[index * 2] / maximumAmplitude
                    let maximum = waveform.samples[(index * 2) + 1] / maximumAmplitude
                    let barTop = centerY - CGFloat(maximum) * centerY * 0.88
                    let barBottom = centerY - CGFloat(minimum) * centerY * 0.88
                    let intensity = (abs(minimum) + abs(maximum)) / 2
                    let color =
                        intensity > 0.35
                        ? secondaryAccent.opacity(0.52)
                        : accent.opacity(0.24)
                    let rect = CGRect(
                        x: CGFloat(index) * sampleWidth,
                        y: barTop,
                        width: max(1, sampleWidth - 0.5),
                        height: max(1, barBottom - barTop)
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
            .frame(width: stripWidth)
        }
    }

    #if DEBUG
        #Preview("Mac Music Waveform Track") {
            MacMusicWaveformTrack(
                waveform: MusicWaveformPreviewLoader.waveform,
                stripWidth: 1_200,
                accent: PrismediaColor.materialSpectrumGreen,
                secondaryAccent: PrismediaColor.materialSpectrumCyan
            )
            .frame(width: 600, height: 52, alignment: .leading)
            .clipped()
        }
    #endif
#endif
