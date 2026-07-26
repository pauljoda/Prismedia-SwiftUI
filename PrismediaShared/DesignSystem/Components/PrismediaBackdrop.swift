import SwiftUI

/// The black, softly spectral content layer beneath system navigation and Liquid Glass.
public struct PrismediaBackdrop: View {
    public init() {}

    public var body: some View {
        ZStack {
            PrismediaColor.background

            MeshGradient(
                width: 5,
                height: 4,
                points: [
                    .init(0, 0), .init(0.25, 0), .init(0.5, 0), .init(0.75, 0), .init(1, 0),
                    .init(0, 0.33), .init(0.25, 0.33), .init(0.5, 0.33), .init(0.75, 0.33), .init(1, 0.33),
                    .init(0, 0.67), .init(0.25, 0.67), .init(0.5, 0.67), .init(0.75, 0.67), .init(1, 0.67),
                    .init(0, 1), .init(0.25, 1), .init(0.5, 1), .init(0.75, 1), .init(1, 1),
                ],
                colors: [
                    PrismediaColor.materialSpectrumRed,
                    PrismediaColor.materialSpectrumOrange,
                    .black,
                    PrismediaColor.materialSpectrumViolet,
                    PrismediaColor.materialSpectrumMagenta,
                    PrismediaColor.materialSpectrumOrange,
                    PrismediaColor.materialSpectrumYellow,
                    PrismediaColor.materialSpectrumGreen,
                    PrismediaColor.materialSpectrumCyan,
                    PrismediaColor.materialSpectrumMagenta,
                    .black,
                    PrismediaColor.materialSpectrumGreen,
                    PrismediaColor.materialSpectrumCyan,
                    PrismediaColor.materialSpectrumBlue,
                    PrismediaColor.materialSpectrumViolet,
                    PrismediaColor.materialSpectrumRed,
                    .black,
                    PrismediaColor.materialSpectrumBlue,
                    PrismediaColor.materialSpectrumViolet,
                    PrismediaColor.materialSpectrumMagenta,
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
