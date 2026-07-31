import CoreMedia
import VideoToolbox

struct AppleVideoPlaybackProfile: Encodable {
    let maxStreamingBitrate: Int? = nil
    let directPlayProfiles: [VideoDirectPlayProfileRequest]

    static var current: Self {
        make(
            supportsCompatibilityRenderer: VideoPlaybackRendererPolicy.platformSupportsCompatibilityRenderer
        )
    }

    static func make(supportsCompatibilityRenderer: Bool) -> Self {
        let modernVideoCodecs = [
            "h264", supports(.hevc) ? "hevc" : nil, supports(.av1) ? "av1" : nil, supports(.vp9) ? "vp9" : nil,
        ]
        .compactMap { $0 }.joined(separator: ",")
        let movVideoCodecs = ["h264", supports(.hevc) ? "hevc" : nil, "mpeg4", "mjpeg"]
            .compactMap { $0 }.joined(separator: ",")
        let transportStreamVideoCodecs = ["h264", supports(.hevc) ? "hevc" : nil]
            .compactMap { $0 }.joined(separator: ",")
        var directPlayProfiles: [VideoDirectPlayProfileRequest] = [
            .init(
                type: PrismediaContractCodes.StreamKind.video,
                container: "mp4,m4v", videoCodec: modernVideoCodecs,
                audioCodec: "aac,ac3,eac3,alac,flac"
            ),
            .init(
                type: PrismediaContractCodes.StreamKind.video,
                container: "mov", videoCodec: movVideoCodecs,
                audioCodec: "aac,ac3,eac3,alac,mp3,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le"
            ),
            .init(
                type: PrismediaContractCodes.StreamKind.video,
                container: "mpegts,ts", videoCodec: transportStreamVideoCodecs,
                audioCodec: "aac,ac3,eac3,mp3"
            ),
        ]
        if supportsCompatibilityRenderer {
            directPlayProfiles.append(
                .init(
                    type: PrismediaContractCodes.StreamKind.video,
                    container: "mkv,matroska",
                    videoCodec: modernVideoCodecs,
                    audioCodec: "aac,ac3,eac3,truehd,mlp,dts,dtshd,alac,flac,mp3,opus,vorbis"
                )
            )
        }
        return Self(directPlayProfiles: directPlayProfiles)
    }

    static var supportedVideoRangeTypes: [String] {
        var ranges = ["SDR"]
        if supports(.hevc) {
            ranges += ["HDR10", "HDR10Plus", "HLG"]
        }
        if supports(.dolbyVision) { ranges.append("DOVI") }
        return ranges
    }

    private enum Codec { case hevc, av1, vp9, dolbyVision }
    private static func supports(_ codec: Codec) -> Bool {
        switch codec {
        case .hevc: VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
        case .av1: VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)
        case .vp9: VTIsHardwareDecodeSupported(kCMVideoCodecType_VP9)
        case .dolbyVision: VTIsHardwareDecodeSupported(kCMVideoCodecType_DolbyVisionHEVC)
        }
    }
}
