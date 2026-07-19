#if os(tvOS)
    import SwiftUI

    struct TVPlaybackScanIndicator: View {
        let side: VideoPlayerGestureSide
        let rate: Float

        var body: some View {
            Label {
                Text("\(rate.formatted(.number.precision(.fractionLength(0))))×")
                    .monospacedDigit()
            } icon: {
                Image(systemName: side == .left ? "backward.fill" : "forward.fill")
            }
            .font(.title3.bold())
            .foregroundStyle(PrismediaColor.onMedia)
            .padding(.horizontal, PrismediaSpacing.large)
            .frame(height: 52)
            .glassEffect(.regular, in: .capsule)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(side == .left ? "Rewind" : "Fast Forward")
            .accessibilityValue("\(rate.formatted(.number.precision(.fractionLength(0)))) times")
            .accessibilityIdentifier("video-player.scan-indicator")
        }
    }

    #if DEBUG
        #Preview("TV Playback Scan Indicator") {
            TVPlaybackScanIndicator(side: .right, rate: 4)
                .padding(80)
                .background(Color.black)
        }
    #endif
#endif
