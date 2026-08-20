/// Canonical libVLC option policy for the Apple compatibility renderer.
///
/// Dolby Vision Profile 5 has no HDR10-compatible base layer. iOS and tvOS
/// therefore need both halves of Prismedia's patched path: VideoToolbox must
/// preserve the RPU metadata, and the GLES renderer must apply its reshape.
enum VLCCompatibilityPlaybackOptions {
    static let videoToolboxCodec = ":codec=videotoolbox,any"
    static let hardwareDecoderOnly = ":videotoolbox-hw-decoder-only=1"
    static let avcodecVideoToolbox = ":avcodec-hw=videotoolbox"
    static let profile5Metadata = ":videotoolbox-dovi-profile5"
    static let profile5FullRangeSurface = ":videotoolbox-cvpx-chroma=420f"
    static let glesVideoOutput = "--vout=gles2"
    static let profile5Reshape = "--gl-dovi-profile5"

    static func mediaOptions(
        dolbyVisionProfile: Int?,
        platform: VLCCompatibilityPlaybackPlatform,
        hardwareDecoderAvailable: Bool
    ) -> [String] {
        guard hardwareDecoderAvailable else { return [] }

        if dolbyVisionProfile == 5, platform == .iOS || platform == .tvOS {
            return [
                videoToolboxCodec,
                hardwareDecoderOnly,
                profile5Metadata,
                profile5FullRangeSurface,
            ]
        }

        switch platform {
        case .tvOS:
            return [videoToolboxCodec, hardwareDecoderOnly]
        case .iOS, .macOS:
            return [videoToolboxCodec, hardwareDecoderOnly, avcodecVideoToolbox]
        }
    }

    static func playerOptions(
        dolbyVisionProfile: Int?,
        platform: VLCCompatibilityPlaybackPlatform
    ) -> [String] {
        guard dolbyVisionProfile == 5, platform == .iOS || platform == .tvOS else {
            return []
        }
        return [glesVideoOutput, profile5Reshape]
    }
}
