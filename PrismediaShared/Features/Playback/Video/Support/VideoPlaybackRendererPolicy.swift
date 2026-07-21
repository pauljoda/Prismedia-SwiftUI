import Foundation

enum VideoPlaybackRendererPolicy {
    static func renderer(
        delivery: VideoPlaybackDelivery,
        sourceContainer: String?,
        dynamicRange: VideoPlaybackDynamicRange,
        bitDepth: Int?,
        supportsCompatibilityRenderer: Bool,
        preferredEngine: VideoPlaybackEngine
    ) -> VideoPlaybackRenderer {
        guard supportsCompatibilityRenderer else { return .native }
        switch preferredEngine {
        case .native:
            return .native
        case .vlc:
            return .compatibility
        case .automatic:
            let container = sourceContainer?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if delivery == .direct, container == "mkv" || container == "matroska" {
                return .compatibility
            }
            return renderer(
                delivery: delivery,
                dynamicRange: dynamicRange,
                bitDepth: bitDepth,
                supportsCompatibilityRenderer: supportsCompatibilityRenderer
            )
        }
    }

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
        #if canImport(TVVLCKit) || canImport(MobileVLCKit) || canImport(VLCKit)
            true
        #else
            false
        #endif
    }
}
