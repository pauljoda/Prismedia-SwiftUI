import CoreGraphics

public enum PrismediaLayout {
    public static let hairline: CGFloat = 1
    public static let focusRing: CGFloat = 3

    #if os(tvOS)
        public static let minimumHitTarget: CGFloat = 66
        public static let loadingAnimationHeight: CGFloat = 220
        public static let loadingPrismMark: CGFloat = 148
        public static let loadingLightLineWidth: CGFloat = 3
        public static let loadingSpectrumBandWidth: CGFloat = 12
        public static let loadingBeamGlowRadius: CGFloat = 10
        public static let loadingSpectrumGlowRadius: CGFloat = 14
        public static let loadingImpactGlowRadius: CGFloat = 52
    #elseif os(macOS)
        public static let minimumHitTarget: CGFloat = 28
        public static let loadingAnimationHeight: CGFloat = 128
        public static let loadingPrismMark: CGFloat = 72
        public static let loadingLightLineWidth: CGFloat = 1.5
        public static let loadingSpectrumBandWidth: CGFloat = 7
        public static let loadingBeamGlowRadius: CGFloat = 6
        public static let loadingSpectrumGlowRadius: CGFloat = 8
        public static let loadingImpactGlowRadius: CGFloat = 32
    #else
        public static let minimumHitTarget: CGFloat = 44
        public static let loadingAnimationHeight: CGFloat = 168
        public static let loadingPrismMark: CGFloat = 104
        public static let loadingLightLineWidth: CGFloat = 2
        public static let loadingSpectrumBandWidth: CGFloat = 9
        public static let loadingBeamGlowRadius: CGFloat = 8
        public static let loadingSpectrumGlowRadius: CGFloat = 11
        public static let loadingImpactGlowRadius: CGFloat = 42
    #endif
    public static let readableContentWidth: CGFloat = 760
    public static let mediaContentWidth: CGFloat = 1_280
    public static let backdropBlur: CGFloat = 72
    public static let backdropOverscan: CGFloat = 1.16
    public static let brandMark: CGFloat = 104
    public static let compactBrandMark: CGFloat = 72
    public static let televisionBrandMark: CGFloat = 148
}
