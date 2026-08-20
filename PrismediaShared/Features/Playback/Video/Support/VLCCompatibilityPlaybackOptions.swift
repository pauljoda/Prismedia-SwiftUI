/// Canonical libVLC option policy for the Apple compatibility renderer.
///
/// Dolby Vision Profile 5 has no HDR10-compatible base layer. Every Apple
/// platform therefore needs both halves of Prismedia's patched path:
/// VideoToolbox must preserve the RPU metadata, and the platform OpenGL renderer
/// must apply its reshape. iOS and tvOS use VLC's GLES output; macOS uses VLC's
/// native CGL output, which supports the decoder's 10-bit P010 surface.
enum VLCCompatibilityPlaybackOptions {
    /// VLCKit otherwise installs libVLC's console logger at debug verbosity,
    /// which emits every HTTP/2 data frame and can include signed stream URLs.
    static let quietLogging = "--quiet"
    /// `--quiet` disables VLC's console sink, while this inherited value also
    /// keeps FFmpeg from writing codec transform diagnostics directly.
    static let quietVerbosity = "--verbose=-1"
    /// VLC deliberately treats ordinary Matroska cues as untrusted. On HTTP
    /// streams it also reports that it cannot fast-seek, so VLC refuses to
    /// validate those cues and falls back to scanning from the first cluster.
    /// Prismedia enables VLC's existing trusted Matroska demux only for direct
    /// Matroska files selected from the user's probed library.
    static let trustedMatroskaDemux = ":demux=mkv_trusted"
    static let videoToolboxCodec = ":codec=videotoolbox,any"
    static let hardwareDecoderOnly = ":videotoolbox-hw-decoder-only=1"
    static let avcodecVideoToolbox = ":avcodec-hw=videotoolbox"
    static let profile5Metadata = ":videotoolbox-dovi-profile5"
    static let profile5FullRangeSurface = ":videotoolbox-cvpx-chroma=420f"
    static let glesVideoOutput = "--vout=gles2"
    static let profile5Reshape = "--gl-dovi-profile5"

    static func containerOptions(trustMatroskaCues: Bool) -> [String] {
        trustMatroskaCues ? [trustedMatroskaDemux] : []
    }

    static func mediaOptions(
        dolbyVisionProfile: Int?,
        platform: VLCCompatibilityPlaybackPlatform,
        hardwareDecoderAvailable: Bool
    ) -> [String] {
        guard hardwareDecoderAvailable else { return [] }

        if dolbyVisionProfile == 5 {
            var options = [
                videoToolboxCodec,
                hardwareDecoderOnly,
                profile5Metadata,
            ]
            if platform != .macOS {
                options.append(profile5FullRangeSurface)
            }
            return options
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
        guard dolbyVisionProfile == 5 else {
            return [quietLogging, quietVerbosity]
        }
        var options = [quietLogging, quietVerbosity, profile5Reshape]
        if platform != .macOS {
            options.insert(glesVideoOutput, at: 2)
        }
        return options
    }
}
