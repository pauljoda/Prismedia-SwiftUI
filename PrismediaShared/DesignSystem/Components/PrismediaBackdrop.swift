import SwiftUI

/// The black, softly spectral content layer beneath system navigation and Liquid Glass.
public struct PrismediaBackdrop: View {
    public init() {}

    public var body: some View {
        ZStack {
            PrismediaColor.background

            MeshGradient(
                width: 4,
                height: 3,
                points: [
                    .init(0, 0), .init(0.33, 0), .init(0.67, 0), .init(1, 0),
                    .init(0, 0.5), .init(0.33, 0.5), .init(0.67, 0.5), .init(1, 0.5),
                    .init(0, 1), .init(0.33, 1), .init(0.67, 1), .init(1, 1),
                ],
                colors: [
                    PrismediaColor.spectrumBlue, .black,
                    PrismediaColor.spectrumRed, PrismediaColor.spectrumOrange,
                    .black, PrismediaColor.spectrumCyan,
                    PrismediaColor.spectrumYellow, .black,
                    PrismediaColor.spectrumViolet, PrismediaColor.spectrumMagenta,
                    .black, PrismediaColor.spectrumGreen,
                ],
                background: .black,
                smoothsColors: true
            )
            .scaleEffect(PrismediaLayout.backdropOverscan)
            .blur(radius: PrismediaLayout.backdropBlur)
            .opacity(PrismediaOpacity.backdropSpectrum)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Backdrop · Spectral Dark") {
        PrismediaBackdrop()
            .preferredColorScheme(.dark)
    }
#endif
