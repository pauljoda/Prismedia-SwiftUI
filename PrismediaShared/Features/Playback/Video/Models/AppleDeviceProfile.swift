import CoreMedia
import VideoToolbox

struct AppleDeviceProfile: Encodable {
    let directPlayProfiles: [AppleDirectPlayProfile]

    enum CodingKeys: String, CodingKey { case directPlayProfiles = "DirectPlayProfiles" }

    static var current: Self {
        let modernVideoCodecs = [
            "h264", supports(.hevc) ? "hevc" : nil, supports(.av1) ? "av1" : nil, supports(.vp9) ? "vp9" : nil,
        ]
        .compactMap { $0 }.joined(separator: ",")
        return Self(directPlayProfiles: [
            .init(
                type: "Video", container: "mp4,m4v", videoCodec: modernVideoCodecs, audioCodec: "aac,ac3,eac3,alac,flac"
            ),
            .init(
                type: "Video", container: "mov", videoCodec: modernVideoCodecs + ",mpeg4,mjpeg",
                audioCodec: "aac,ac3,eac3,alac,mp3,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le"),
            .init(type: "Video", container: "mpegts,ts", videoCodec: modernVideoCodecs, audioCodec: "aac,ac3,eac3,mp3"),
        ])
    }

    static var supportedVideoRangeTypes: [String] {
        var ranges = ["SDR"]
        if supports(.hevc) { ranges += ["HDR10", "HDR10Plus", "HLG"] }
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
