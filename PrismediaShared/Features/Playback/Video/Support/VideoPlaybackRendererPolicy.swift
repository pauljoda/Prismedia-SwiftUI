enum VideoPlaybackRendererPolicy {
    static func renderer(
        delivery: VideoPlaybackDelivery,
        dynamicRange: VideoPlaybackDynamicRange,
        bitDepth: Int?,
        supportsCompatibilityRenderer: Bool
    ) -> VideoPlaybackRenderer {
        guard supportsCompatibilityRenderer,
            delivery == .direct,
            dynamicRange != .sdr,
            let bitDepth,
            bitDepth < 10
        else { return .native }
        return .compatibility
    }

    static var platformSupportsCompatibilityRenderer: Bool {
        #if os(tvOS)
            true
        #else
            false
        #endif
    }
}
